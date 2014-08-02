#include <IOKit/IOKitLib.h>
#include <AudioToolbox/AudioToolbox.h>
#include <cassert>
#include <functional>

struct KeyboardBacklight {
	enum {
		kGetSensorReadingID = 0,
		kGetLEDBrightnessID = 1,
		kSetLEDBrightnessID = 2,
		kSetLEDFadeID = 3,
	};

	mach_port_t connect;

	KeyboardBacklight() {
		io_service_t serviceObject = IOServiceGetMatchingService(
			kIOMasterPortDefault, IOServiceMatching("AppleLMUController")
		);
		assert(serviceObject);

		kern_return_t kr = IOServiceOpen(serviceObject, mach_task_self(), 0, &connect);
		assert(kr == KERN_SUCCESS);

		IOObjectRelease(serviceObject);
	}

	void set(uint64_t brightness) {
		uint32_t outputCount = 1;
		uint64_t input[] = {0, brightness}, output;

		kern_return_t kr = IOConnectCallMethod(
			connect, kSetLEDBrightnessID,
			input, sizeof(input)/sizeof(*input),
			nil, 0,
			&output, &outputCount,
			nil, 0
		);

		assert(kr == KERN_SUCCESS);
	}

	void fade(uint64_t brightness, uint64_t time) {
		uint32_t outputCount = 1;
		uint64_t input[] = {0, brightness, time}, output;

		kern_return_t kr = IOConnectCallMethod(
			connect, kSetLEDFadeID,
			input, sizeof(input)/sizeof(*input),
			nil, 0,
			&output, &outputCount,
			nil, 0
		);

		assert(kr == KERN_SUCCESS);
	}

};

class MicContext {

	static void audio_queue_cb(
		void *userData,
		AudioQueueRef inAQ,
		AudioQueueBufferRef inBuffer,
		const AudioTimeStamp *inStartTime,
		UInt32 inNumberPacketDescriptions,
		const AudioStreamPacketDescription *inPacketDescs
	) { static_cast<MicContext*>(userData)->processBuffer(inAQ, inBuffer, inStartTime, inNumberPacketDescriptions, inPacketDescs); }

	AudioQueueRef m_queue;

	void processBuffer(
		AudioQueueRef inAQ,
		AudioQueueBufferRef inBuffer,
		const AudioTimeStamp *inStartTime,
		UInt32 inNumberPacketDescriptions,
		const AudioStreamPacketDescription *inPacketDescs
	) {
		cb(inBuffer);
		AudioQueueEnqueueBuffer(m_queue, inBuffer, 0, nullptr);
	}

	void require(OSStatus err, const char *name) {
		if (err) {
			fprintf(stderr, "%s: %d\n", name, err);
			exit(1);
		}
	}

	public:

	std::function<void(AudioQueueBufferRef)> cb;
	const double m_sample_rate;

	MicContext (std::function<void(AudioQueueBufferRef)> _cb, double sample_rate = 44100) :
		cb(_cb), m_sample_rate(sample_rate) {

		AudioStreamBasicDescription description;

		description.mSampleRate       = m_sample_rate;
		description.mFormatID         = kAudioFormatLinearPCM;
		description.mFormatFlags      = kAudioFormatFlagIsFloat;
		description.mBytesPerPacket   = sizeof(double);
		description.mFramesPerPacket  = 1;
		description.mBytesPerFrame    = sizeof(double);
		description.mChannelsPerFrame = 1;
		description.mBitsPerChannel   = sizeof(double) * 8;


		require(AudioQueueNewInput(
			&description, audio_queue_cb, this, CFRunLoopGetCurrent(),
			kCFRunLoopCommonModes, 0, &m_queue
		), "AudioQueueNewOutput");

	}

	void start() {
		for (size_t i = 0; i < 2; i++) {
			AudioQueueBufferRef buffer;
			require(AudioQueueAllocateBuffer(m_queue, 512, &buffer), "AudioQueueAllocateBuffer");
			AudioQueueEnqueueBuffer(m_queue, buffer, 0, nullptr);
		}

		require(AudioQueueStart(m_queue, NULL), "AudioQueueStart");
		CFRunLoopRun();
	}
};

int main() {
	KeyboardBacklight kb;
	MicContext mic([&](AudioQueueBufferRef buf){
		double total{0};

		for (size_t i = 0; i < buf->mAudioDataBytesCapacity / sizeof(double); i++) {
			total += fabs(static_cast<double *>(buf->mAudioData)[i]);
		}

		double average = total / buf->mAudioDataBytesCapacity;

		kb.set(fmin(0xfff, average / 0.04 * 0xfff));
	});
	mic.start();
}

