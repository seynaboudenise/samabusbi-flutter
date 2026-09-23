# SAMA BUS - démarrage sous Windows

1. Installer Flutter.
2. Ouvrir PowerShell dans ce dossier.
3. Exécuter :

```powershell
flutter create .
flutter pub get
flutter run -d chrome
```

Pour Android :

```powershell
flutter devices
flutter run -d emulator-5554
```

`flutter create .` génère les dossiers de plateforme (android/windows/web/etc.) sans remplacer les fichiers de `lib/` et `assets/`.
