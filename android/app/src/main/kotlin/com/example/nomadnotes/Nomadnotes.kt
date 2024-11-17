package com.example.carnet_de_voyage

import android.app.Application
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory

class NomadNotesApp : Application() {

    override fun onCreate() {
        super.onCreate()

        // Log pour vérifier l'initialisation
        Log.d("NomadNotesApp", "Application onCreate() démarrée")

        try {
            // Initialiser Firebase
            FirebaseApp.initializeApp(this)
            Log.d("NomadNotesApp", "Firebase initialisé avec succès")

            // Activer Firebase App Check en mode débogage
            val appCheck = FirebaseAppCheck.getInstance()
            appCheck.installAppCheckProviderFactory(DebugAppCheckProviderFactory.getInstance())
            Log.d("NomadNotesApp", "Firebase App Check activé avec le mode débogage")
        } catch (e: Exception) {
            Log.e("NomadNotesApp", "Erreur lors de l'initialisation de Firebase : ${e.message}", e)
        }
    }
}