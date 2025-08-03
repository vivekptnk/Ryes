# ElevenLabs Integration Verification Checklist

## Prerequisites
1. [ ] Obtain an ElevenLabs API key from https://elevenlabs.io
2. [ ] Ensure you have network connectivity
3. [ ] Build and run the Ryes app in Xcode

## Test Steps

### 1. Basic Integration Test
1. [ ] Open the Ryes app
2. [ ] Navigate to Settings tab
3. [ ] Tap "Test ElevenLabs Integration"
4. [ ] Enter your ElevenLabs API key
5. [ ] Tap "Save API Key"
6. [ ] Verify the key is saved (should show "API Key Configured" with green checkmark)

### 2. Account Information Test
1. [ ] After saving API key, verify account info loads:
   - [ ] Subscription tier displays
   - [ ] Character usage shows (e.g., "5000 / 10000")
   - [ ] Characters remaining is calculated correctly

### 3. Voice Loading Test
1. [ ] Tap "Load Available Voices"
2. [ ] Verify voices load (status should show "Loaded X voices")
3. [ ] Select a voice from the picker
4. [ ] Verify voice details show (category, description)

### 4. Voice Synthesis Test
1. [ ] With a voice selected, tap "Test Voice Synthesis"
2. [ ] Listen for audio playback
3. [ ] Verify status shows "✓ Audio playing successfully!"
4. [ ] Try different voices to ensure variety works

### 5. Default Voice Test
1. [ ] Tap "Test Default Alarm Voice"
2. [ ] Verify the default voice works without selecting a specific voice
3. [ ] This tests the alarm-optimized voice settings

### 6. Error Handling Tests
1. [ ] Remove API key and try to synthesize (should show error)
2. [ ] Enter invalid API key and test (should show authentication error)
3. [ ] Enter text longer than 5000 characters (should be disabled)
4. [ ] Turn off network and test (should show network error)

### 7. Security Tests
1. [ ] Remove API key
2. [ ] Force quit the app
3. [ ] Reopen app and verify API key persists or is cleared as expected
4. [ ] Check that API key field is secure (dots instead of text)

## Expected Results

### ✅ Success Indicators
- API key saves and persists across app launches
- Account information displays correctly
- Voices load and display in picker
- Audio synthesizes and plays through device speakers
- Different voices produce different audio output
- Error messages are clear and helpful

### ❌ Failure Indicators
- API key doesn't save or disappears
- No account info or voices load
- Audio doesn't play or app crashes
- Errors are cryptic or unhelpful
- Network requests hang indefinitely

## Debugging Tips

### If API Key Won't Save:
- Check Keychain access in device settings
- Ensure app has proper entitlements
- Try deleting and reinstalling app

### If Voices Don't Load:
- Verify API key is valid at elevenlabs.io
- Check network connectivity
- Look for rate limit errors (429 status)

### If Audio Won't Play:
- Check device volume and mute switch
- Verify audio permissions
- Test with built-in iOS sounds first
- Check Audio Session configuration in console logs

### Console Logs to Check:
Look for these log messages in Xcode console:
- "🔊 Audio session category configured"
- Network request/response details
- Any error messages from ElevenLabsError

## Manual Code Verification

You can also verify the implementation by checking these files exist:
- `/Ryes/Services/KeychainManager.swift` - Secure API storage
- `/Ryes/Services/ElevenLabsAPIClient.swift` - API client
- `/Ryes/Services/ElevenLabsError.swift` - Error handling
- `/Ryes/Services/ElevenLabsModels.swift` - Data models
- `/Ryes/Services/VoiceSynthesisService.swift` - Main service
- `/Ryes/Features/Settings/ElevenLabsTestView.swift` - Test UI

## Integration Points

The ElevenLabs integration should be ready to:
1. Store API keys securely in iOS Keychain
2. Make authenticated API requests
3. Handle audio data and playback
4. Report errors gracefully
5. Respect rate limits and quotas
6. Work with the alarm system (next task)

## Next Steps

Once verified:
1. Task 7: Implement voice cloning workflow
2. Task 8: Add dynamic message generation
3. Task 9: Integrate with alarm triggering