/*
 * watch.c
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */

#include "watch.h"

static watch_time_t myWatch; // 현재 시간을 저장할 구조체 변수
static uint32_t prevTime = 0; // 이전 ms 기록용

void Watch_Init() {
	FND_Init();
	// 초기 시간 설정 (00:00:00:000)
	myWatch.hour = 0;
	myWatch.min = 0;
	myWatch.sec = 0;
	myWatch.msec = 0;
	prevTime = millis();
}

void Watch_Execute() {
//	Watch_Update();  // 시간 계산

	// 0.5초(500ms) 주기로 DP 상태 결정
	if (myWatch.msec < 500) {
		FND_SetDP(2, ON);  // 500ms 미만일 때 켬
	} else {
		FND_SetDP(2, OFF); // 500ms 이상일 때 끔
	}

	Watch_Display(); // FND 표시 (분, 초)
}

void Watch_Update() {
	uint32_t currentTime = millis();
	uint32_t diff = currentTime - prevTime;

	if (diff > 0) {
		myWatch.msec += diff;
		prevTime = currentTime;

		// 1초 경과 시 (1000ms)
		if (myWatch.msec >= 1000) {
			myWatch.msec %= 1000;
			myWatch.sec++;

			if (myWatch.sec >= 60) {
				myWatch.sec = 0;
				myWatch.min++;
				if (myWatch.min >= 60) {
					myWatch.min = 0;
					myWatch.hour++;
					if (myWatch.hour >= 24) {
						myWatch.hour = 0;
					}
				}
			}
			// 매 초마다 UART 출력 호출
			Watch_UartPrint();
		}
	}
}

void Watch_Display() {
	// FND에 분(Min)과 초(Sec)를 표시 (예: 12분 34초 -> 1234)
	uint16_t fndData = (myWatch.min * 100) + myWatch.sec;
	FND_SetNum(fndData);
	FND_DispDigit(); // 다이내믹 배정 실행
}

void Watch_UartPrint() {
	// VITIS의 UART 기본 출력(STDOUT)이 설정되어 있다고 가정함
	// 형식: HH : MM : SS
	printf("%02d : %02d : %02d\n", myWatch.hour, myWatch.min, myWatch.sec);
}
