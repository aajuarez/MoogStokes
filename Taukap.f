
      subroutine taukap
c******************************************************************************
c     This routine calculates the line absorption coefficient and the line  
c     opacity at wavelength *wave* for all lines in the spectrum            
c******************************************************************************

      implicit real*8 (a-h,o-z)
      include 'Atmos.com'
      include 'Linex.com'
      include 'Dummy.com'
      real*8 kapnu_I(100), kapnu_Q(100), kapnu_V(100), old_voigt,
     .       new_voigt, new_fv


c*****compute the total line opacity at each depth    
      
      do i=1,ntau     
         kapnu_I(i) = 0.0
         kapnu_Q(i) = 0.0
         kapnu_V(i) = 0.0
         kapnu(i) = 0.0
         do j=lim1,lim2
            v = 2.997929d10*dabs(wave-wave1(j))/
     .             (wave1(j)*dopp(j,i))            
c            x = sqrt(log(2.0))*10000.0*(1.0/wave-1.0/wave1(j))/dopp(j,i)
c            y = sqrt(log(2.0))*a(j,i)
            old_voigt = voigt(a(j,i),v)
c            call complexVoigt(x, y, new_voigt, new_fv)
c            write (*,*) i, j, dopp(j,i), wave, old_voigt, new_voigt, new_fv
c            read (*,*)
            if (width(j) .eq. 0.0) then
                kapnu_I(i) = kapnu_I(i) + kapnu0(j,i)*old_voigt*
     .             (sin(phi)**2.0)/2.0
                kapnu_Q(i) = kapnu_Q(i) + kapnu0(j,i)*old_voigt*
     .             (sin(phi)**2.0)/2.0
            else
                kapnu_I(i) = kapnu_I(i) + kapnu0(j,i)*old_voigt*
     .             (1.0+cos(phi)**2.0)/4.0
                kapnu_Q(i) = kapnu_Q(i) - kapnu0(j,i)*old_voigt*
     .             (sin(phi)**2.0)/4.0
                kapnu_V(i) = kapnu_V(i) + kapnu0(j,i)*old_voigt*
     .             (cos(phi))/2.0*width(j)
            endif
         enddo                                     

                                                       
c*****do the same for the strong lines
         if (dostrong .gt. 0) then
            do j=nlines+1,nlines+nstrong
               v = 2.997929d10*dabs(wave-wave1(j))/
     .             (wave1(j)*dopp(j,i)) 
c               kapnu(i) = kapnu(i) + kapnu0(j,i)*voigt(a(j,i),v)
               old_voigt = voigt(a(j,i),v)
               if (width(j) .eq. 0.0) then
                   kapnu_I(i) = kapnu_I(i)+ kapnu0(j,i)*old_voigt*
     .                 (sin(phi)**2.0)/2.0
                   kapnu_Q(i) = kapnu_Q(i)+ kapnu0(j,i)*old_voigt*
     .                 (sin(phi)**2.0)/2.0
               else
                   kapnu_I(i) = kapnu_I(i)+ kapnu0(j,i)*old_voigt*
     .                 (1.0+cos(phi)**2.0)/4.0
                   kapnu_Q(i) = kapnu_Q(i)- kapnu0(j,i)*old_voigt*
     .                 (sin(phi)**2.0)/4.0
                   kapnu_V(i) = kapnu_V(i)+kapnu0(j,i)*old_voigt*
     .                 (cos(phi))/2.0*width(j)
               endif
            enddo
         endif
         eta_I(i) = kapnu_I(i)/kaplam(i)
         eta_Q(i) = kapnu_Q(i)/kaplam(i)
         eta_V(i) = kapnu_V(i)/kaplam(i)
c         write (nf11out,321) wave,tauref(i),t(i),kapnu_I(i),kapnu_Q(i),
c     .          kapnu_V(i), kaplam(i), kapref(i)
      enddo      
c      close(nf11out)

c*****compute the optical depths                                            
c      first = tauref(1)*kapnu(1)/kapref(1)
c      dummy1(1) = rinteg(xref,dummy1,taunu,ntau,0.)
c      taunu(i) = first
c      do i=2,ntau                                                     
c          taunu(i) = taunu(i-1)+taunu(i)
c      enddo

      return                                              
321   format (f11.3, e11.3, f11.1, 5e11.3)
c322   format (f11.3, 4e11.3)
      end                                                

