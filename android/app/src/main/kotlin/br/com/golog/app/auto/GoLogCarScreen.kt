package br.com.golog.app.auto

import android.annotation.SuppressLint
import android.app.Application
import android.util.Log
import androidx.car.app.CarContext
import androidx.car.app.SurfaceContainer
import androidx.car.app.model.Action
import androidx.car.app.model.ActionStrip
import androidx.car.app.model.CarIcon
import androidx.car.app.model.Distance
import androidx.car.app.model.Template
import androidx.car.app.navigation.NavigationManager
import androidx.car.app.navigation.NavigationManagerCallback
import androidx.car.app.navigation.model.Maneuver
import androidx.car.app.navigation.model.MessageInfo
import androidx.car.app.navigation.model.NavigationTemplate
import androidx.car.app.navigation.model.RoutingInfo
import androidx.car.app.navigation.model.Step
import androidx.car.app.navigation.model.TravelEstimate
import androidx.core.graphics.drawable.IconCompat
import androidx.lifecycle.Observer
import com.google.android.gms.maps.GoogleMap
import com.google.android.libraries.mapsplatform.turnbyturn.model.NavInfo
import com.google.android.libraries.mapsplatform.turnbyturn.model.StepInfo
import com.google.android.libraries.navigation.NavigationUpdatesOptions.GeneratedStepImagesType
import com.google.maps.flutter.navigation.AndroidAutoBaseScreen
import com.google.maps.flutter.navigation.GoogleMapsNavigatorHolder
import java.time.ZonedDateTime
import kotlin.math.max

/**
 * Tela do GoLog no Android Auto.
 *
 * O [AndroidAutoBaseScreen] (do google_navigation_flutter) desenha o mapa do
 * Navigation SDK na superfície do carro e compartilha a mesma sessão de
 * navegação aberta pelo Flutter no celular. Aqui acrescentamos:
 *  - o card de manobras (turn-by-turn) e o ETA, a partir do feed [NavInfo];
 *  - mensagens de estado (sem entrega, calculando rota, chegou) quando não há
 *    guidance ativo, usando os eventos enviados pelo Flutter
 *    (lib/util/android_auto_bridge.dart).
 */
class GoLogCarScreen(carContext: CarContext) : AndroidAutoBaseScreen(carContext) {

    private companion object {
        const val TAG = "GoLogCarScreen"

        // Eventos Flutter -> carro (ver AndroidAutoBridge no Dart).
        const val EVENT_DELIVERY = "delivery"
        const val EVENT_ARRIVED = "arrived"
        const val EVENT_CLEAR = "clear"

        // Evento carro -> Flutter.
        const val EVENT_HOST_STOP = "hostStopNavigation"
    }

    private var routingInfo: RoutingInfo? = null
    private var travelEstimate: TravelEstimate? = null

    /** Parada atual informada pelo app no celular, ou null se não há entrega aberta. */
    private var deliveryTitle: String? = null
    private var deliveryAddress: String? = null
    private var arrived = false

    private var surfaceAvailable = false
    private var navInfoObserverRegistered = false
    private var turnByTurnRegistered = false
    private var hostNavigationStarted = false

    private val navigationManager: NavigationManager
        get() = carContext.getCarService(NavigationManager::class.java)

    private val navigationManagerCallback = object : NavigationManagerCallback {
        // Motorista encerrou a navegação pelo carro (ex.: "X" no card de ETA).
        override fun onStopNavigation() {
            GoogleMapsNavigatorHolder.getNavigator()?.stopGuidance()
            sendCustomNavigationAutoEvent(EVENT_HOST_STOP, emptyMap<String, Any>())
            endHostNavigation()
            clearGuidance()
            invalidate()
        }
    }

    // O LiveData é Java: na prática o valor pode chegar nulo.
    private val navInfoObserver = Observer<NavInfo> { navInfo: NavInfo? -> onNavInfo(navInfo) }

    // ------------------------------------------------------------------
    // Feed turn-by-turn
    // ------------------------------------------------------------------

    private fun startListeningIfPossible() {
        if (!surfaceAvailable || !mIsNavigationReady) return
        if (!navInfoObserverRegistered) {
            GoogleMapsNavigatorHolder.addNavInfoObserver(navInfoObserver)
            navInfoObserverRegistered = true
        }
        if (!turnByTurnRegistered) {
            val app = carContext.applicationContext as? Application ?: return
            turnByTurnRegistered = GoogleMapsNavigatorHolder.registerTurnByTurnService(
                app,
                1,
                GeneratedStepImagesType.BITMAP,
            )
            if (!turnByTurnRegistered) Log.w(TAG, "Falha ao registrar o serviço turn-by-turn")
        }
    }

    private fun stopListening() {
        if (navInfoObserverRegistered) {
            GoogleMapsNavigatorHolder.removeNavInfoObserver(navInfoObserver)
            navInfoObserverRegistered = false
        }
        if (turnByTurnRegistered) {
            GoogleMapsNavigatorHolder.unregisterTurnByTurnService()
            turnByTurnRegistered = false
        }
    }

    private fun onNavInfo(navInfo: NavInfo?) {
        val current = navInfo?.currentStep
        if (current == null) {
            if (routingInfo != null || travelEstimate != null) {
                clearGuidance()
                endHostNavigation()
                invalidate()
            }
            return
        }

        startHostNavigation()
        arrived = false

        val builder = RoutingInfo.Builder().setCurrentStep(
            toCarStep(current),
            Distance.create(
                max(navInfo.distanceToCurrentStepMeters?.toDouble() ?: 0.0, 0.0),
                Distance.UNIT_METERS,
            ),
        )
        navInfo.remainingSteps?.firstOrNull()?.let { builder.setNextStep(toCarStep(it)) }
        current.lanesBitmap?.let {
            builder.setJunctionImage(CarIcon.Builder(IconCompat.createWithBitmap(it)).build())
        }
        routingInfo = builder.build()

        val remainingSeconds = max(navInfo.timeToFinalDestinationSeconds?.toLong() ?: 0L, 0L)
        travelEstimate = TravelEstimate.Builder(
            Distance.create(
                max(navInfo.distanceToFinalDestinationMeters?.toDouble() ?: 0.0, 0.0),
                Distance.UNIT_METERS,
            ),
            ZonedDateTime.now().plusSeconds(remainingSeconds),
        ).setRemainingTimeSeconds(remainingSeconds).build()

        invalidate()
    }

    private fun toCarStep(step: StepInfo): Step {
        val type = ManeuverConverter.toCarManeuverType(step.maneuver)
        val maneuver = Maneuver.Builder(type)
        // Os tipos de rotatória exigem metadados; sem eles build() lança
        // IllegalArgumentException.
        when (type) {
            Maneuver.TYPE_ROUNDABOUT_ENTER_AND_EXIT_CW_WITH_ANGLE,
            Maneuver.TYPE_ROUNDABOUT_ENTER_AND_EXIT_CCW_WITH_ANGLE ->
                maneuver.setRoundaboutExitAngle(ManeuverConverter.roundaboutExitAngle(step.maneuver))
            Maneuver.TYPE_ROUNDABOUT_ENTER_AND_EXIT_CW,
            Maneuver.TYPE_ROUNDABOUT_ENTER_AND_EXIT_CCW ->
                maneuver.setRoundaboutExitNumber(max(step.roundaboutTurnNumber ?: 1, 1))
        }
        step.maneuverBitmap?.let {
            maneuver.setIcon(CarIcon.Builder(IconCompat.createWithBitmap(it)).build())
        }
        return Step.Builder()
            .setRoad(step.fullRoadName ?: "")
            .setCue(step.fullInstructionText ?: "")
            .setManeuver(maneuver.build())
            .build()
    }

    private fun clearGuidance() {
        routingInfo = null
        travelEstimate = null
    }

    // ------------------------------------------------------------------
    // Estado de navegação no host (Android Auto)
    // ------------------------------------------------------------------

    private fun startHostNavigation() {
        if (hostNavigationStarted) return
        navigationManager.setNavigationManagerCallback(navigationManagerCallback)
        navigationManager.navigationStarted()
        hostNavigationStarted = true
    }

    private fun endHostNavigation() {
        if (!hostNavigationStarted) return
        navigationManager.navigationEnded()
        hostNavigationStarted = false
    }

    // ------------------------------------------------------------------
    // Ciclo de vida (AndroidAutoBaseScreen)
    // ------------------------------------------------------------------

    override fun onNavigationReady(ready: Boolean) {
        super.onNavigationReady(ready)
        if (ready) {
            startListeningIfPossible()
        } else {
            stopListening()
            endHostNavigation()
            clearGuidance()
        }
        invalidate()
    }

    override fun onSurfaceAvailable(surfaceContainer: SurfaceContainer) {
        super.onSurfaceAvailable(surfaceContainer)
        surfaceAvailable = true
        navigationManager.setNavigationManagerCallback(navigationManagerCallback)
        startListeningIfPossible()
    }

    override fun onSurfaceDestroyed(surfaceContainer: SurfaceContainer) {
        super.onSurfaceDestroyed(surfaceContainer)
        surfaceAvailable = false
        stopListening()
        endHostNavigation()
        navigationManager.clearNavigationManagerCallback()
    }

    override fun onCustomNavigationAutoEventFromFlutter(event: String, data: Any) {
        val map = data as? Map<*, *>
        when (event) {
            EVENT_DELIVERY -> {
                deliveryTitle = map?.get("title")?.toString()?.takeIf { it.isNotBlank() }
                deliveryAddress = map?.get("address")?.toString()?.takeIf { it.isNotBlank() }
                arrived = false
            }
            EVENT_ARRIVED -> {
                arrived = true
                clearGuidance()
                endHostNavigation()
            }
            EVENT_CLEAR -> {
                deliveryTitle = null
                deliveryAddress = null
                arrived = false
                clearGuidance()
                endHostNavigation()
            }
            else -> Log.d(TAG, "Evento desconhecido do Flutter: $event")
        }
        invalidate()
    }

    // ------------------------------------------------------------------
    // Template
    // ------------------------------------------------------------------

    private fun statusMessage(): MessageInfo {
        val title = deliveryTitle
        val builder = when {
            title == null -> MessageInfo.Builder("Nenhuma entrega em andamento")
                .setText("Abra uma parada no app GoLog do celular para iniciar a navegação.")
            arrived -> MessageInfo.Builder("Você chegou: $title")
                .setText("Registre a entrega ou a ocorrência no celular com o veículo parado.")
            else -> MessageInfo.Builder(title)
                .setText(deliveryAddress ?: "Calculando rota…")
        }
        return builder.build()
    }

    @SuppressLint("MissingPermission") // permissão de localização tratada no Flutter
    override fun onGetTemplate(): Template {
        // A ActionStrip é obrigatória no NavigationTemplate.
        val actions = ActionStrip.Builder().addAction(
            Action.Builder()
                .setTitle("Centralizar")
                .setOnClickListener {
                    try {
                        mGoogleMap?.followMyLocation(GoogleMap.CameraPerspective.TILTED)
                    } catch (e: Exception) {
                        Log.w(TAG, "Não foi possível centralizar o mapa", e)
                    }
                }
                .build(),
        )

        val template = NavigationTemplate.Builder()
            .setActionStrip(actions.build())
            .setMapActionStrip(ActionStrip.Builder().addAction(Action.PAN).build())

        val routing = routingInfo
        if (routing != null) {
            template.setNavigationInfo(routing)
            travelEstimate?.let { template.setDestinationTravelEstimate(it) }
        } else {
            template.setNavigationInfo(statusMessage())
        }
        return template.build()
    }
}
