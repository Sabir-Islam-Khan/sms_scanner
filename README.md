# bKash SMS Scanner

A Flutter app that automatically monitors incoming SMS messages from bKash, parses transaction details, and sends them to a remote API.

## Features

- **Background SMS Monitoring**: Continuously listens for incoming SMS even when the app is in background
- **bKash SMS Detection**: Automatically identifies SMS messages from bKash
- **Transaction Parsing**: Extracts amount and TrxID from bKash SMS messages
- **API Integration**: Automatically sends transaction data to your API endpoint

## How It Works

1. The app requests SMS and phone permissions on startup
2. Once permissions are granted, it starts listening for incoming SMS
3. When an SMS is received, it checks if it's from bKash (contains "bkash" or "trxid")
4. If it's a bKash SMS, it parses:
   - **Amount**: Extracted from "received Tk X,XXX.XX"
   - **TrxID**: Extracted from "TrxID XXXXXXXXXX"
5. Sends a POST request to: `http://143.244.191.183:3003/transactions`
   ```json
   {
     "transaction_id": "CLP5GGO1NZ",
     "amount": 2000.00,
     "method": "BKASH"
   }
   ```

## SMS Format Example

```
You have received Tk 2,000.00 from 01776800874. Fee Tk 0.00. Balance Tk 5,087.84. TrxID CLP5GGO1NZ at 25/12/2025 19:18
```

## Running the App

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run on Android device:
   ```bash
   flutter run
   ```

3. Grant SMS and Phone permissions when prompted

4. The app will now automatically monitor and process bKash SMS messages

## Testing

Use the "Test with Sample bKash SMS" button in the app to verify the parsing and API integration without waiting for a real SMS.

## Permissions

The app requires the following Android permissions:
- `RECEIVE_SMS` - To receive incoming SMS
- `READ_SMS` - To read SMS content
- `SEND_SMS` - For telephony package functionality
- `READ_PHONE_STATE` - To access phone state
- `INTERNET` - To make API calls
- `FOREGROUND_SERVICE` - To run in background
- `WAKE_LOCK` - To keep the app active

## Notes

- This app is designed for personal use only
- Works only on Android devices
- The app will continue to monitor SMS even when running in the background
- All transactions are automatically sent to the configured API endpoint

