package br.com.golog.app.auto

import android.content.pm.ApplicationInfo
import androidx.car.app.CarAppService
import androidx.car.app.Session
import androidx.car.app.SessionInfo
import androidx.car.app.validation.HostValidator

/**
 * Ponto de entrada do GoLog no Android Auto.
 *
 * O Android Auto não exibe a UI Flutter: ele se conecta a este serviço
 * (declarado no manifest com a categoria NAVIGATION) e desenha a tela do
 * carro a partir dos templates devolvidos por [GoLogCarScreen]. A navegação
 * em si continua sendo iniciada pelo app no celular; o carro espelha a
 * mesma sessão do Navigation SDK.
 */
class GoLogCarAppService : CarAppService() {

    override fun createHostValidator(): HostValidator {
        val debuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        // Em debug aceita qualquer host (Desktop Head Unit, emuladores). Em
        // release, só os hosts oficiais (Android Auto / Automotive) da lista
        // mantida pela própria Car App Library.
        return if (debuggable) {
            HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
        } else {
            HostValidator.Builder(applicationContext)
                .addAllowedHosts(androidx.car.app.R.array.hosts_allowlist_sample)
                .build()
        }
    }

    override fun onCreateSession(sessionInfo: SessionInfo): Session = GoLogCarSession()
}
