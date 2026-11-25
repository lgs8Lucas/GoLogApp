package br.com.golog.app.auto

import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session

/** Sessão do carro: uma única tela de navegação. */
class GoLogCarSession : Session() {
    override fun onCreateScreen(intent: Intent): Screen = GoLogCarScreen(carContext)
}
