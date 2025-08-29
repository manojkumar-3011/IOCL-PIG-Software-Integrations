/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * pig_eucld_dynamics.h
 *
 * Code generation for function 'pig_eucld_dynamics'
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
void pig_eucld_dynamics(const emlrtStack *sp, real_T t, const real_T x[17],
                        const real_T u[6], const real_T params[8],
                        real_T x_next[17]);

/* End of code generation (pig_eucld_dynamics.h) */
