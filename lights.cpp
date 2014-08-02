#include <IOKit/IOKitLib.h>
#include <cassert>

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


int main() {
	KeyboardBacklight kb;
	kb.set(0xfff);
}

