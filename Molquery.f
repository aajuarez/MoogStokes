
      subroutine molquery
c******************************************************************************
c     This routine discovers whether a species being analyzed in EW 
c     force-fitting mode is involved in molecular equilibrium (=M.E.) 
c     calculations as well; the variables is set appropriately
c******************************************************************************

      implicit real*8 (a-h,o-z)
      include 'Linex.com'
      include 'Mol.com'
      include 'Pstuff.com'

      molflag = 0
      iabatom = idint(atom1(lim1obs)+0.0001)


c*****the species is an atom:
c*****search for it in the list of elements done in M.E.
      if (atom1(lim1line) .lt. 100.) then
         if (neq .ne. 0) then
            do n=1,neq
               if (iabatom .eq. iorder(n)) molflag = 1
            enddo
         endif
      endif
      return


c*****the species is a molecule:
c*****halt if M.E. wasn't done or didn't include this species
      if (neq .eq. 0) then
         lscreen = lscreen + 2
         write (array,1001) iabatom
         call prinfo (lscreen)
         stop
      endif
      call sunder(atom1(lim1obs),ia,ib)
      do n=1,neq
         if (ia.eq.iorder(n) .or. ib.eq.iorder(n)) molflag = ia
      enddo
      if (molflag .eq. 0) then
         lscreen = lscreen + 2
         write (array,1002) iabatom
         call prinfo (lscreen)
         stop
      endif
      molflag = 1

c*****if molecule is a hydride, the non-H element will be varied
      if (ia.eq.1 .or. ib.eq.1) then
         if (ia .eq. 1) then
            iabatom = ib
         else
            iabatom = ia
         endif


c*****for other molecules, the user specifies which element will be varied
      else
         write (array,1003) iabatom
         nchars = 49
         call getnum (nchars,ikount+1,xnum,shortnum)
         iabatom = idint(xnum+0.0001)
         if (iabatom.ne.ia .and. iabatom.ne.ib) then
            write (array,1003)
            stop
         endif
      endif
      return


c*****format statements
1001  format ('YOU FORGOT TO DO MOLECULAR EQUILIBRIUM FOR ',
     .        'SPECIES ', i3, '; I QUIT!')
1002  format ('YOUR MOLECULAR EQUILIBRIUM DOES NOT INCLUDE ',
     .        'THE ATOMS FOR SPECIES ', i3, '; I QUIT!')
1003  format ('MOLECULAR LINES OF SPECIES ', i3, ' ARE NEXT: ',
     .        'WHICH ATOMIC NUMBER SHOULD BE CHANGED? ')
1004  format ('YOUR CHOICE OF ATOM TO VARY IS ', i5,
     .        '; DOESNT MAKE SENSE; I QUIT')


      end
