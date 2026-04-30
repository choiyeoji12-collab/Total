/*
 * watch.h
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */

#ifndef SRC_AP_WATCH_WATCH_H_
#define SRC_AP_WATCH_WATCH_H_

#include <stdint.h>
#include <stdio.h>

#include "../../driver/FND/FND.h"
//#include "../../driver/button/button.h"
#include "../../common/common.h"

typedef struct {
    uint8_t hour;
    uint8_t min;
    uint8_t sec;
    uint16_t msec;
} watch_time_t;

void Watch_Init();
void Watch_Execute();
void Watch_Update();
void Watch_Display();
void Watch_UartPrint();

#endif /* SRC_AP_WATCH_WATCH_H_ */
