# CashOverflow

App iOS per la gestione del budget familiare. Scansiona scontrini, traccia le spese e condividi il portafoglio con la tua famiglia.

## Funzionalità

- **Scansione scontrini** — Scatta una foto o scegli dalla galleria. Gemini AI estrae automaticamente esercente, importo, data e articoli
- **Inserimento manuale** — Aggiungi spese a mano quando preferisci
- **15 categorie** — Alimentari, ristoranti, trasporti, utenze, salute, shopping, intrattenimento, istruzione, casa, assicurazioni, abbonamenti, personale, viaggi, regali, altro
- **Portafoglio condiviso** — Invita familiari via email per gestire insieme il budget
- **Budget mensile** — Imposta un tetto di spesa e monitora l'andamento con barra di progresso
- **Navigazione mensile** — Scorri tra i mesi, filtra per categoria, visualizza i totali

## Architettura

```
MVVM + SwiftUI (iOS 17+)
├── Firebase Auth          → Autenticazione
├── Cloud Firestore        → Database real-time e sincronizzazione
├── Firebase Storage       → Upload immagini scontrini
└── Google Gemini 2.0 Flash → Estrazione dati da foto scontrini
```

### Struttura progetto

```
CashOverflow/
├── App/                → Entry point e navigazione root
├── Models/             → Expense, Wallet, User, ExpenseCategory
├── Services/           → Auth, Wallet, Expense, ReceiptScanner
├── ViewModels/         → Logica di presentazione (MVVM)
└── Views/
    ├── Main/           → Login, lista spese, tab bar
    ├── Receipt/        → Cattura foto, conferma dati estratti
    ├── Wallet/         → Gestione portafoglio e membri
    ├── Settings/       → Profilo e configurazione API key
    └── Components/     → Componenti riutilizzabili
```

## Requisiti

- Xcode 15+
- iOS 17+
- Account Firebase con Auth, Firestore e Storage abilitati
- API key Google Gemini

## Setup

1. **Clona il repository**

   ```bash
   git clone https://github.com/maroffo/CashOverflow.git
   ```

2. **Configura Firebase**

   - Crea un progetto su [Firebase Console](https://console.firebase.google.com)
   - Abilita **Authentication** (email/password), **Cloud Firestore** e **Storage**
   - Scarica `GoogleService-Info.plist` e copialo in `CashOverflow/`

3. **Apri il progetto in Xcode**

   ```bash
   open Package.swift
   ```

   Xcode risolverà automaticamente le dipendenze (Firebase SDK, Google Generative AI SDK).

4. **Configura Gemini**

   Al primo avvio, vai in **Impostazioni** nell'app e inserisci la tua API key di Google Gemini. La puoi ottenere su [Google AI Studio](https://aistudio.google.com).

5. **Esegui su simulatore o dispositivo**

   Seleziona un target iOS 17+ e premi Run.

## Regole Firestore (esempio base)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /wallets/{walletId} {
      allow read, write: if request.auth != null
        && request.auth.uid in resource.data.memberIds;
      match /expenses/{expenseId} {
        allow read, write: if request.auth != null
          && request.auth.uid in get(/databases/$(database)/documents/wallets/$(walletId)).data.memberIds;
      }
    }
    match /invites/{inviteId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
  }
}
```

## Licenza

MIT
