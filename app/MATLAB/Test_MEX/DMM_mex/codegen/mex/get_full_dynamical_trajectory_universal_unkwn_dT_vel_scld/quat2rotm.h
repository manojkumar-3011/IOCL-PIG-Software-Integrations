/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * quat2rotm.h
 *
 * Code generation for function 'quat2rotm'
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
void quat2rotm(const emlrtStack *sp, const real_T q[4], real_T R[9]);

/* End of code generation (quat2rotm.h) */
