/*
 * ap_main.c
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */


#include "xil_printf.h"

#include "ap_main.h"
#include "../common/common.h"
#include "UpCounter/UpCounter.h"
#include "../HAL/TMR/TMR.h"
#include "interrupt.h"

#include "watch/watch.h"
#include "../driver/button/button.h"

typedef enum {
	MODE_UPCOUNTER, MODE_WATCH
} app_mode_t;

hBtn_t btn_l;
app_mode_t currentMode = MODE_UPCOUNTER;

//void ap_init() {
//	UpCounter_Init();
//	SetupInterruptSystem();
//
//	TMR_SetPSC(TMR1, 100 - 1);
//	TMR_SetARR(TMR1, 1000000 - 1);
//	TMR_StartIntr(TMR1);
//	TMR_StartTimer(TMR1);
//
//	TMR_SetPSC(TMR2, 100 - 1);
//	TMR_SetARR(TMR2, 2000000 - 1);
//	TMR_StartIntr(TMR2);
//	TMR_StartTimer(TMR2);
//
//}
//
//void ap_excute() {
//
//	while (1) {
//		UpCounter_Execute();
//
//		millis_inc();
//		delay_ms(1);
//	}
//}

void ap_init() {
	UpCounter_Init();
	Watch_Init();

	Button_Init(&btn_l, GPIOA, GPIO_PIN_5);
}

void ap_excute() {

	while (1) {
		Watch_Update();
		if (Button_GetState(&btn_l) == ACT_PUSHED) {
			currentMode =
					(currentMode == MODE_UPCOUNTER) ?
							MODE_WATCH : MODE_UPCOUNTER;

			for (int i = 0; i < 4; i++) {
				FND_SetDP(i, OFF);
			}
		}

		switch (currentMode) {
		case MODE_UPCOUNTER:
			UpCounter_Execute();
			break;

		case MODE_WATCH:
			Watch_Execute();
			break;
		}

		millis_inc();
		delay_ms(1);
	}
}
