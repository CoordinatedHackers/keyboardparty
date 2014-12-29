import AppKit
import AVFoundation

protocol KeyboardParty {}

class TypingKeyboardParty: KeyboardParty {
    let kb = KeyboardBacklight()
    let eventMonitor: AnyObject? = nil
    
    init() {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true])
        
        eventMonitor = NSEvent.addGlobalMonitorForEventsMatchingMask(
            NSEventMask.KeyDownMask,
            handler: {[unowned self] (event: NSEvent!) -> Void in
                self.kb.set(0xfff)
                self.kb.fade(0, duration: 100)
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