import AppKit
import AVFoundation

protocol KeyboardParty {}

let soundFiles = { (files: [String]) -> [NSURL] in
    let bundle = NSBundle.mainBundle()
    var urls = [NSURL]()
    for file in files {
        urls.append(bundle.URLForResource(file, withExtension: "wav")!)
    }
    return urls
}([
    "148432__neatonk__piano-loud-c4",
    "148513__neatonk__piano-loud-d4",
    "148524__neatonk__piano-loud-e4",
    "148503__neatonk__piano-loud-g4",
    "148488__neatonk__piano-loud-a4",
    "148431__neatonk__piano-loud-c5"
])

func chooseSound(seed: Int, keyCode: UInt16) -> NSURL {
    return soundFiles[((Int(keyCode) * 269) ^ seed) % soundFiles.count]
}

class StrongIndependentSoundPlayer: NSObject, AVAudioPlayerDelegate {
    var holdSelf: StrongIndependentSoundPlayer? = nil
    let player: AVAudioPlayer
    
    init(player: AVAudioPlayer) {
        self.player = player
        super.init()
        self.holdSelf = self
        player.delegate = self
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        holdSelf = nil
    }
}

class TypingKeyboardParty: KeyboardParty {
    let kb = KeyboardBacklight()
    let eventMonitor: AnyObject? = nil
    
    init() {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true])
        var oldBrightness: UInt64 = 0
        var probablyFading = false
        var cancelLastDelay: (() -> ())? = nil
        
        eventMonitor = NSEvent.addGlobalMonitorForEventsMatchingMask(
            NSEventMask.KeyDownMask,
            handler: {[unowned self] (event: NSEvent!) -> Void in
                
                StrongIndependentSoundPlayer(player: AVAudioPlayer(
                    contentsOfURL: chooseSound(4, event.keyCode),
                    fileTypeHint: AVFileTypeWAVE,
                    error: nil
                )!).player.play()
                
                if event.ARepeat { return }
                if !probablyFading {
                    oldBrightness = self.kb.get()
                    probablyFading = true
                }
                cancelLastDelay?()
                cancelLastDelay = delay(200) {
                    probablyFading = false
                    cancelLastDelay = nil
                }
                self.kb.set(0xfff)
                self.kb.fade(oldBrightness, duration: 200)
            }
        )!
    }
    
    deinit {
        NSEvent.removeMonitor(eventMonitor!)
    }
}

class SoundKeyboardParty: NSObject, KeyboardParty, AVCaptureAudioDataOutputSampleBufferDelegate {
    let kb = KeyboardBacklight()
    let queue = dispatch_queue_create("SoundParty", nil)
    let session = AVCaptureSession()
    var peak: Float = 0
    
    override init() {
        super.init()
        session.addInput(AVCaptureDeviceInput(
            device: AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio), error: nil)
        )
        let dataOutput = AVCaptureAudioDataOutput()
        dataOutput.audioSettings = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVSampleRateKey: 44100
        ]
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        session.addOutput(dataOutput)
        session.startRunning()
    }
    
    deinit {
        session.stopRunning()
        kb.fade(0, duration: 100)
    }
    
    // MARK: AVCaptureAudioDataOutputSampleBufferDelegate
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        let numSamples = CMSampleBufferGetNumSamples(sampleBuffer)
        let audioBuffer = CMSampleBufferGetDataBuffer(sampleBuffer)
        
        var length: UInt = 0
        var buf: UnsafeMutablePointer<Int8> = nil
        CMBlockBufferGetDataPointer(
            CMSampleBufferGetDataBuffer(sampleBuffer),
            0, &length, nil, &buf
        )
        
        if peak > 1 { peak *= 0.95 }
        
        var maxAmplitude: Float = 0
        let count = Int(length) / (sizeof(Float) / sizeof(Int8))
        
        for sample in UnsafeMutableBufferPointer(start: UnsafeMutablePointer<Float>(buf), count: count) {
            let amplitude = abs(sample)
            peak = max(peak, amplitude)
            maxAmplitude = max(maxAmplitude, amplitude)
        }
        
        kb.set(UInt64(0xfff * (maxAmplitude / peak)))
    }
}