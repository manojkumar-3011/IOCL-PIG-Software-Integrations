/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * expm.h
 *
 * Code generation for function 'expm'
 *
 */

#pragma once

/* Include files */
#include "rtwtypes.h"
#include "emlrt.h"
#include "mex.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Function Declarations */
void PadeApproximantOfDegree(const emlrtStack *sp, const real_T A[16],
                             uint8_T m, real_T F[16]);

/* End of code generation (expm.h) */
