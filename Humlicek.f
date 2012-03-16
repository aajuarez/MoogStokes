      SUBROUTINE CPF12(X, Y, WR, WI)
C ROUTINE COMPUTES THE REAL (WR) AND IMAGINARY (WI) PARTS OF THE COMPLEX
C PROBABILITY FUNCTION W(Z)=EXP(-Z**2)*ERF(-I*Z) IN THE UPPER HALF PLANE
C Z=X+I*Y (I.E. FOR Y>=0)
C MAXIMUM RELATIVE ERROR OF WR IS <2*10**(-6), THAT OF WI <5*10**(-6)
      DIMENSION T(6),C(6),S(6)
      DATA(T(I)