      subroutine ODEINT(YSTART, NVAR, X1, X2, EPS, H1, HMIN, NOK, NBAD)
c     .             DERIVS, RKQC)
c*****************************************************************************
c     Runge-Kutta driver with adaptive stepsize control.  Integrate the
c     NVAR starting values YSTART from X1 to X2 with accuracy EPS, storing
c     intermediate results in the common block /PATH/.  H1 should be set
c     as a guessed first stepsize, HMIN as the minimum allowed stepsize
c     (can be zero).  On output NOK and NBAD are the number of good and bad
c     (but retried and fixed) steps taken, and YSTART is replaced by values
c     at the end of the integration interval.  DERIVS is the user-supplied
c     subroutine for calculating the right-hand side derivative, while RKQC
c     is the name of the stepper routine to be used.  PATH contains its own
c     information about how often an intermediate value is to be stored.
c*****************************************************************************

      include "Linex.com"
      PARAMETER (MAXSTP=100000,NMAX=10, TWO=2.0, ZERO=0.0, TINY=1.e-30)
      COMMON /PATH/ KMAX, KOUNT, KXSAV, XP(200), YP(10,200)
c           USER STORAGE FOR INTERMEDIATE RESULTS.  PRESET DXSAV AND KMAX

c      EXTERNAL DERIVS, RKQC
      real*8 YSTART(NVAR), YSCAL(NVAR), Y(NVAR), DYDX(NVAR), X, X1, X2,
     .         EPS,H, H1, HMIN, NOK, NBAD, XSAV, DXSAV, HDID,HNEXT,TEFF,
     .         EI, EQ, EV, STEPSIZE
c      real*8 YSTART(*), X1, X2, H1
      include "Atmos.com"

c      write (*,*) "Starting ODE INT"
      X=X1
      H=SIGN(H1,X2-X1)
      NOK=0
      NBAD=0
      KOUNT=0
      do I=1,NVAR
          Y(I)=YSTART(I)
      enddo
c      write (*,*) Y(1), Y(2), Y(3), Y(4), "Checkpoint A"
      XSAV=X-DXSAV*TWO
      do NSTP=1,MAXSTP
c          write (*,*) NSTP, XSAV, "Checkpoint B"
c          call tester(x,Y, DYDX)
          CALL DERIVS(10.0**X,Y,DYDX)
          STEPSIZE = 10.0**(X+log10(H))-10.0**(X)
c          STEPSIZE = 10.0**(X+H)-10.0**(X)
          do I=1,NVAR
              YSCAL(I)=MAX(ABS(Y(I))+ABS(STEPSIZE*DYDX(I))+TINY, 100.0)
c              YSCAL(I)=ABS(Y(I))+ABS(H*DYDX(I))+TINY
          enddo
c          IF (KMAX.GT.0) THEN
c              IF (ABS(X-XSAV).GT.(DXSAV)) THEN
c                  IF (KOUNT.LT.KMAX-1) THEN
c                      KOUNT=KOUNT+1
c                      XP(KOUNT)=X
c                      DO I=1, NVAR
c                          YP(I,KOUNT)=Y(I)
c                      ENDDO
c                      XSAV=X
c                  ENDIF
c              ENDIF
c          ENDIF

c          write (*,*) "H = ", H, H1, HMIN
c          write (*,*) "Boundaries = ", X1, X2
          IF ((X+H-X2)*(X+H-X1).GT.ZERO) H=X2-X
c          write (*,*) "EPS = ", EPS
c          write (*,*) "H = ", H, H1, HMIN
c          STEPSIZE = 10.0**(X+H)-10.0**(X1)
          CALL RKQC(Y,DYDX,NVAR,X,H,EPS,YSCAL,HDID,HNEXT)
c          write (*,*) "HDID = ", HDID, HNEXT
          IF(HDID.EQ.H)THEN
              NOK=NOK+1
c              CALL LINTERPOLATE(ETA_I, 10.0**X, EI)
c              CALL LINTERPOLATE(ETA_Q, 10.0**X, EQ)
c              CALL LINTERPOLATE(ETA_V, 10.0**X, EV)
c              write (nf11out, 321) X, Y, EI, EQ, EV
          ELSE
              NBAD=NBAD+1
          ENDIF
c          TEFF = 0.0
c          CALL LINTERPOLATE(T, 10.0**X, TEFF)
c          write (nf11out,321) X, TEFF, EI, EQ, EV
          IF( (X-X2)*(X2-X1).GE.ZERO)THEN
              DO I=1,NVAR
                  YSTART(I)=Y(I)
              ENDDO
c              IF(KMAX.NE.0)THEN
c                 KOUNT=KOUNT+1
c                 XP(KOUNT)=X
c                 DO I=1,NVAR
c                     YP(I,KOUNT)=Y(I)
c                 ENDDO
c              ENDIF
c              close(nf11out)
              RETURN
          ENDIF
          IF (ABS(HNEXT).LT.log10(HMIN)) THEN
c              write (*,*) HNEXT, HMIN
              PAUSE 'Stepsize smaller than minimum.'
          ENDIF
c          write (*,*) 'Checkpoint A : ', X, H, HNEXT
          H=HNEXT
      enddo
      PAUSE 'Too many steps!'
      RETURN

321   format (8e13.5)
      END

      SUBROUTINE LINTERPOLATE(Y_OLD, X_NEW, Y_NEW)
      IMPLICIT NONE
      include "Atmos.com"
      include "Linex.com"
c      include "Factor.com"
c      include "Pstuff.com"
c      include "Dummy.com"
      real*8 Y_OLD(100), X_NEW, Y_NEW, SLOPE
      integer I
      
      DO I=1,NTAU-1
          IF ((TAUREF(I+1)*KAPLAM(I+1)/(KAPREF(I+1)*MU))+1.0e-10
     .         .GE.X_NEW) THEN
              GOTO 10
          ENDIF
      ENDDO
c      write (*,*) I, X_NEW, TAUREF(I)*KAPLAM(I)/(KAPREF(I)*MU)
c      write (*,*) TAUREF(I), KAPLAM(I), KAPREF(I), MU, NTAU
10    SLOPE=(Y_OLD(I+1)-Y_OLD(I))/(TAUREF(I+1)*KAPLAM(I+1)/
     .   (KAPREF(I+1)*MU)-TAUREF(I)*KAPLAM(I)/(KAPREF(I)*MU))
      Y_NEW = Y_OLD(I)+SLOPE*(X_NEW-TAUREF(I)*KAPLAM(I)/(KAPREF(I)*MU))
      RETURN
      END

      SUBROUTINE DERIVS(X,Y,DYDX)
C*****************************************************************************
C     This subroutine calculates the derivatives of the stokes parameters at
C     Tau = X.
C*****************************************************************************
      implicit NONE
      include "Atmos.com"
      include "Linex.com"
c      include "Factor.com"
c      include "Pstuff.com"
c      include "Dummy.com"
      real*8 X, Y(4), DYDX(4), B, TEFF, EI, EQ, EV
c      real*8 X, Y(4), DYDX(4)
      
c      write (*,*) X,Y, DYDX, 'Checkpoint C'
      CALL LINTERPOLATE(ETA_I, X, EI)
      CALL LINTERPOLATE(ETA_Q, X, EQ)
      CALL LINTERPOLATE(ETA_V, X, EV)
      CALL LINTERPOLATE(T, X, TEFF)

      CALL PLANCK(TEFF, B)
c      write (*,*) X, EI, EQ, EV, B
      DYDX(1) = (1.0+EI)*Y(1)+EQ*Y(2)+EV*Y(3) - (1.0+EI)*B
      DYDX(2) = EQ*Y(1)+(1.0+EI)*Y(2) - (EQ)*B
      DYDX(3) = EV*Y(1)+(1.0+EI)*Y(3) - (EV)*B
      DYDX(4) = Y(4)-B
c      write (*,*) "Derivatives: ", DYDX
      RETURN
      END

      SUBROUTINE RKDUMB(VSTART, NVAR, X1, X2, NSTEP)
C*****************************************************************************
c     Starting from initial values VSTART for NVAR functions, known at X1 use
c     fourth-order Runge-Kutta to advance NSTEP equal increments to X2.  The 
c     user-supplied subroutine DERIVS(X,V,DVDX) evaluates derivatives. Results
c     Are stored in the common block PATH.  Be sure to dimension the common
c     block appropriately
c*****************************************************************************
      INCLUDE "Atmos.com"
      INCLUDE "Linex.com"
      INTEGER NSTEP
      REAL*8 VSTART(NVAR), V(NVAR), DV(NVAR), Y(NVAR, NSTEP), X, X1, X2,
     .          H, VNEW(NVAR), TEFF, EI, EQ, EV, STEPSIZE

      DO I = 1, NVAR
          V(I)=VSTART(I)
          Y(I,1)=V(I)
      ENDDO
      X = X1
      H = (X2-X1)/NSTEP
      DO K = 1, NSTEP
          CALL DERIVS(10.0**X, V, DV)
          STEPSIZE = 10.0**(X+H)-10.0**(X)
          CALL RK4(V, DV, NVAR, X, STEPSIZE, V)
          CALL LINTERPOLATE(T, 10.0**X, TEFF)
          CALL LINTERPOLATE(ETA_I, 10.0**X, EI)
          CALL LINTERPOLATE(ETA_Q, 10.0**X, EQ)
          CALL LINTERPOLATE(ETA_V, 10.0**X, EV)
          WRITE (NF11OUT,321) X, TEFF, EI, EQ, EV, V(1), V(4)
          IF (X+H.EQ.X) PAUSE 'STEPSIZE NOT SIGNIFICANT IN RKDUMB'
          X=X+H
          DO I = 1,NVAR
              Y(I, K+1)=V(I)
C              V(I) = VNEW(I)
          ENDDO
      ENDDO
      DO J = 1,NVAR
         VSTART(J)=V(J)
      ENDDO
      RETURN
321   format (7e13.5)
      END

C      SUBROUTINE RK3(Y, DYDX, NVAR, X, H, YOUT)    
C      END

      
      SUBROUTINE RKQC(Y,DYDX,N,X,HTRY,EPS,YSCAL,HDID,HNEXT)
c*****************************************************************************
c     Fifth-order Runge-Kutta step with monitoring of local truncation error
c     to ensure accuracy and adjust stepsize.  Input are the dependent
c     variable vector Y of length N and its derivative DYDX at the starting
c     VALUE of the independent variable X.  Also input are the stepsize to
c     be attempted HTRY, the required accuracy EPS, and the vector YSCAL
c     against which the error is scaled.  On output, Y, and X are replaced by
c     their new values, HDID is the stepsize which was actually accomplished,
c     and HNEXT is the estimated next stepsize.  DERIVS is the user-supplied
c     subroutine that computes the right-hand side derivatives.
c*****************************************************************************
      PARAMETER (NMAX=10,PGROW=-0.20,PSHRINK=-0.25,FCOR=1./15.,ONE=1.,
     .          SAFETY=0.9,ERRCON=6.e-4)
c          THE VALUE ERROCON EQUALS (4/SAFETY)**(1/PGROW)
c      EXTERNAL DERIVS
      real*8 Y(N),DYDX(N),YSCAL(N),YTEMP(N),YSAV(N),DYSAV(N),
     .         HTRY, EPS, HDID, HNEXT, XSAV, X, HH, H, HT
      XSAV=X
      DO I=1,N
          YSAV(I)=Y(I)
          DYSAV(I)=DYDX(I)
      ENDDO
C        SET STEPSIZE TO THE INITIAL TRIAL VALUE
      HT = HTRY
      H=10.0**(X+HTRY)-10.0**(X)
C        TAKE TWO HALF STEPS
1     HH=0.5*H
      CALL RK4(YSAV,DYSAV,N,XSAV,HH,YTEMP)
      X=log10(10.0**(XSAV)+HH)
      CALL DERIVS(10.0**X, YTEMP,DYDX)
      CALL RK4(YTEMP,DYDX,N,X,HH,Y)
      X=log10(10.0**(XSAV)+H)
c      write (*,*) 'X, XSAV, H, HTRY, HH', X, XSAV, H, HTRY, HH
      IF(X.EQ.XSAV)PAUSE 'STEPSIZE NOT SIGNIFICANT IN RKQC'
C          TAKE THE LARGE STEP
      CALL RK4(YSAV,DYSAV,N,XSAV,H,YTEMP)
C          EVALUATE ACCURACY
c      write (*,*) "YTEMP: ", YTEMP
c      write (*,*) "Y: ", Y
c      write (*,*) "YSCAL: ", YSCAL
      ERRMAX=0
      DO I=1,N
C          YTEMP NOW CONTAINS THE ERROR ESTIMATE
          YTEMP(I)=Y(I)-YTEMP(I)
          ERRMAX=MAX(ERRMAX,ABS(YTEMP(I)/YSCAL(I)))
      ENDDO
C          SCALE TO RELATIVE TO REQUIRED TOLERANCE
c      write (*,*) "ERRMAX: ", ERRMAX, EPS
      ERRMAX=ERRMAX/EPS
      IF(ERRMAX.GT.ONE)THEN
C          TRUNCATION ERROR TOO LARGE, REDUCE STEPSIZE, TRY AGAIN
c          write (*,*) "Loop", ERRMAX, H, HTRY
          HT=SAFETY*HT*(ERRMAX**PSHRINK)
          H=10.0**(X+HT)-10.0**(X)
          GOTO 1
      ELSE
C          STEP SUCCEEDED.  COMPUTE SIZE OF NEXT STEP
          HDID=HT
          IF(ERRMAX.GT.ERRCON)THEN
              HNEXT=SAFETY*HT*(ERRMAX**PGROW)
          ELSE
              HNEXT=4.*HT
          ENDIF
c          write (*,*) "Success!",ERRMAX,H,HNEXT,X,log10(HNEXT+10.0**X)
c          write (*,*) "YSCAL :", YSCAL
c          HNEXT = log10(HNEXT+10.0**X) - X
      ENDIF
c      write (*,*) "HDID = ", HDID
      DO I=1,N
          Y(I)=Y(I)+YTEMP(I)*FCOR
      ENDDO
      RETURN
      END

      SUBROUTINE RK4(Y,DYDX,N,X,H,YOUT)
c*****************************************************************************
c     Given values for N variables Y and their derivatives DYDX known at X,
c     use the fourth-order Runge-Kutta method to advance the solution over an
c     interval H and return the incremented variables as YOUT, which need not
c     be a distinct array from Y.  The user supplies supplies the subroutine
c     DERIVS(X,Y,DYDX) which returns derivatives DYDX at X.
c*****************************************************************************

      PARAMETER (NMAX=4)
      real*8 Y(N),DYDX(N),YOUT(N),YT(NMAX),DYT(NMAX),DYM(NMAX), X, H,
     .          HH, H6, XH
      HH=H*0.5
      H6=H/6.
      XH=10.0**(X)+HH
C          FIRST STEP
      DO I=1,N
          YT(I)=Y(I)+HH*DYDX(I)
      ENDDO
C         SECOND STEP
      CALL DERIVS(XH,YT,DYT)
      DO I=1,N
          YT(I)=Y(I)+HH*DYT(I)
      ENDDO
C         THIRD STEP
      CALL DERIVS(XH,YT,DYM)
      DO I=1,N
          YT(I)=Y(I)+H*DYM(I)
          DYM(I)=DYT(I)+DYM(I)
      ENDDO
C         FOURTH STEP
      CALL DERIVS(10.0**X+H, YT, DYT)
      DO I=1,N
          YOUT(I)=Y(I)+H6*(DYDX(I)+DYT(I)+2.*DYM(I))
      ENDDO
      RETURN
      END
