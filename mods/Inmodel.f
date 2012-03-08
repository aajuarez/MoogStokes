
      subroutine inmodel
c******************************************************************************
c     This subroutine reads in the model
c******************************************************************************

      implicit real*8 (a-h,o-z)
      include 'Chars.com'
      include 'Atmos.com'
      include 'Linex.com'
      include 'Mol.com'
      include 'Quants.com'
      include 'Factor.com'
      include 'Dummy.com'
      real*8 rhox(75), molweight(75) 
      real*8 element(95), logepsilon(95)
      real*8 kaprefmass(75)
      character list*80, list2*70


c*****Read in the key word to define the model type
      modelnum = modelnum + 1
      rewind nfmodel
      read (nfmodel,108) modtype
108   format (a10)
      call out (21)

c*****Read a comment line (usually describing the model)
      read (nfmodel,106) moditle
106   format (a80)                                                       

c*****Read the number of depth points
      read (nfmodel,208) list
      list2 = list(11:)
      read (list2,*) ntau

c*****EITHER: Read in a model from the output of the experimental new
c     MARCS code.  This modtype is called "NEWMARCS".  On each line 
c     the numbers are:
c     tau(5000), t, pe, pgas, rho,  model microtrubulent velocity,
c     and mean opacity (cm^2/gm) at the reference wavelength (5000A).
      if (modtype .eq. 'NEWMARCS  ') then
         read (nfmodel,*) wavref    
         do i=1,ntau
            read (nfmodel,*) tauref(i),t(i),ne(i),pgas(i),rho(i),
     .                         vturb(1),kaprefmass(i)
         enddo
c     OR: Read in a model from the output of the ATLAS code.  This
c     modtype is called "KURUCZ".  On each line the numbers are:
c     rhox, t, pgas, ne, and Rosseland mean opacity (cm^2/gm), and
c     two numbers not used by MOOG.  
      elseif (modtype .eq. 'KURUCZ    ') then
         do i=1,ntau
            read (nfmodel,*) rhox(i),t(i),pgas(i),ne(i),kaprefmass(i)
         enddo
c     OR: Read in a model from the output of the MARCS code.  This modtype
c     type is called "BEGN".  On each line the numbers are:
c     tauross, t, log(pg), log(pe), mol weight, and kappaross.
      elseif (modtype .eq. 'BEGN      ') then
         do i=1,ntau
            read (nfmodel,*) tauref(i),t(i),pgas(i),ne(i),
     .                          molweight(i),  kaprefmass(i)
         enddo
c     OR: Read in a model generated from ATLAS, but without accompanying
c     opacities.  MOOG will need to generate the opacities internally,
c     using a reference wavelength that it reads in before the model.
      elseif (modtype .eq. 'KURTYPE') then
         read (nfmodel,*) wavref    
         do i=1,ntau
            read (nfmodel,*) rhox(i),t(i),pgas(i),ne(i)
         enddo

c     OR: Read in a model generated from ATLAS, with output generated
c     in Padova.  The columns are in somewhat different order than normal
      elseif (modtype .eq. 'KUR-PADOVA') then
         read (nfmodel,*) wavref
         do i=1,ntau
            read (nfmodel,*) tauref(i),t(i),kaprefmass(i),
     .                         ne(i),pgas(i),rho(i)
         enddo
c     OR: Read in a generic model that has a tau scale at a specific 
c     wavelength that is read in before the model.  
c     MOOG will need to generate the opacities internally.
      elseif (modtype .eq. 'GENERIC   ') then
         read (nfmodel,*) wavref    
         do i=1,ntau
            read (nfmodel,*) tauref(i),t(i),pgas(i),ne(i)
         enddo
c     OR: Read in a model from the output of the PHOENIX code.  This
c     model type is called "NEXTGEN".  On each line the numbers are
c     tau(1.2microns), t, pgas, pe, rho, mol weight, opacity (cm^2/g)
c
c
      elseif (modtype .eq. 'NEXTGEN   ') then
         read (nfmodel,*) wavref
         do i=1,ntau
            read (nfmodel,*) tauref(i),t(i),pgas(i),ne(i),
     .                       rho(i),molweight(i),kaprefmass(i)

         enddo
c
c
c

c     OR: quit in utter confusion if those model types are not specified
      else
         write (*,1010)
1010     format('permitted model types are:'/'KURUCZ, BEGN, ',
     .          'KURTYPE, KUR-PADOVA, NEWMARCS, or NEXTGEN, GENERIC')
         write (*,*) 'MOOG quits!'
         stop
      endif

c*****Compute other convenient forms of the temperatures
      do i=1,ntau
          theta(i) = 5040./t(i)
          tkev(i) = 8.6171d-5*t(i)
          tlog(i) = dlog(t(i))
      enddo

c*****Convert from logarithmic Pgas scales, if needed
      if (pgas(ntau)/pgas(1) .lt. 10.) then
         do i=1,ntau                                                    
            pgas(i) = 10.0**pgas(i)                                            
         enddo
      endif

c*****Convert from logarithmic Ne scales, if needed
      if(ne(ntau)/ne(1) .lt. 20.) then
         do i=1,ntau                                                    
            ne(i) = 10.0**ne(i)                                                
         enddo
      endif

c*****Convert from Pe to Ne, if needed
      if(ne(ntau) .lt. 1.0e7) then
         do i=1,ntau                                                    
            ne(i) = ne(i)/1.38054d-16/t(i)                                 
         enddo
      endif


c*****compute the atomic partition functions
      do j=1,95
         elem(j) = dble(j)
         call partfn (elem(j),j)
      enddo


c*****Read the microturbulence (either a single value to apply to 
c     all layers, or a value for each of the ntau layers). 
c     Conversion to cm/sec from km/sec is done if needed
      read (nfmodel,101) (vturb(i),i=1,6)                                   
101   format (6e13.0)                                                     
      if (vturb(2) .ne. 0.) then
         read (nfmodel,101) (vturb(i),i=7,ntau) 
      else
         do i=2,ntau                                                    
            vturb(i) = vturb(1)                                                
         enddo
      endif
      if (vturb(1) .lt. 100.) then
         write (moditle(57:64),157) vturb(1)
157      format ('vt=',f5.2)
         do i=1,ntau
            vturb(i) = 1.0e5*vturb(i)
         enddo
      else
         write (moditle(57:64),157) vturb(1)/1.0e5
      endif

c*****Read in the abundance data, storing the original abundances in xabu
      read (nfmodel,208) list
208   format(a80)
      list2 = list(11:)
      read (list2,*) natoms,abscale
      write (moditle(65:80),158) abscale
158   format ('     [M/H]=',f5.2)
      if(natoms .ne. 0) 
     .         read (nfmodel,*) (element(i),logepsilon(i),i=1,natoms) 
      xhyd = 10.0**xabu(1)                                             
      xabund(1) = 1.0                                                    
      xabund(2) = 10.0**xabu(2)/xhyd                                   
      do i=3,95                                                      
         xabund(i) = 10.0**(xabu(i)+abscale)/xhyd                           
         xabu(i) = xabund(i)
      enddo
      if (natoms .ne. 0) then
         do i=1,natoms                                                  
            xabund(idint(element(i))) = 10.0**logepsilon(i)/xhyd
            xabu(idint(element(i))) = 10.0**logepsilon(i)/xhyd
         enddo
      endif

c*****Compute the mean molecular weight, ignoring molecule formation
c     in this approximation (maybe make more general some day?)
      wtnum = 0.
      wtden = 0.
      do i=1,95
         wtnum = wtnum + xabund(i)*xam(i)
         wtden = wtden + xabund(i)
      enddo
      wtmol = wtnum/(xam(1)*wtden)
      if (modtype .ne. 'BEGN      ') then
         do i=1,ntau
            molweight(i) = wtmol
         enddo
      endif

c*****Compute the density 
      do i=1,ntau                                                    
         rho(i) = pgas(i)*molweight(i)*1.6606d-24/(1.38054d-16*t(i))
      enddo

c*****Calculate the fictitious number density of hydrogen, and then
c     get the number densities of other species needed for opacities, etc.,
c     by running through the molecular equilibrium routine with
c     the main constituents.
c     Note:  ph = (-b1 + dsqrt(b1*b1 - 4.0*a1*c1))/(2.0*a1)
      iatom = 1
      call partfn (dble(iatom),iatom)
      do i=1,ntau    
         th = 5040.0/t(i)         
         ah2 = 10.0**(-(12.7422+(-5.1137+(0.1145-0.0091*th)*th)*th))        
         a1 = (1.0+2.0*xabund(2))*ah2                                       
         b1 = 1.0 + xabund(2)                                               
         c1 = -pgas(i)         
         ph = (-b1/2.0/a1)+dsqrt((b1**2/(4.0*a1*a1))-(c1/a1))
         nhtot(i) = (ph+2.0*ph*ph*ah2)/(1.38054d-16*t(i))                   
      enddo
      amol(1)  = 1.1
      amol(2)  = 101.0
      amol(3)  = 2.1
      amol(4)  = 6.1
      amol(5)  = 608.0
      amol(6)  = 12.1
      amol(7)  = 112.0
      amol(8)  = 13.1
      amol(9)  = 14.1
      amol(10) = 26.1
      nmolhold = nmol
      nmol = 10
      iprhold = ipr(2)
      if (ipr(1) .eq. 2) then
         ipr(2) = 2
         write (nwrite,1001)
1001     format (/'THE FOLLOWING EQUILIBRIUM COMPUTATIONS GET ',
     .           'DENSITIES FOR THE OPACITY CALCULATIONS')
      else
         ipr(2) = 1
      endif
      call eqlib
      nmol = nmolhold
      ipr(2) = iprhold
      neq = 0
c
c     In the number density array "numdens", the elements denoted by
c     the first subscripts are: 1 = H, 2 = He, 3 = C, 4 = Mg, 5 = Al,
c     6 = Si, 7 = Fe
      do i=1,ntau
         numdens(1,1,i) = xamol(1,i)
         numdens(1,2,i) = xmol(1,i)
         numdens(2,1,i) = xamol(2,i)
         numdens(2,2,i) = xmol(3,i)
         numdens(3,1,i) = xamol(3,i)
         numdens(3,2,i) = xmol(4,i)
         numdens(4,1,i) = xamol(5,i)
         numdens(4,2,i) = xmol(6,i)
         numdens(5,1,i) = xamol(6,i)
         numdens(5,2,i) = xmol(8,i)
         numdens(6,1,i) = xamol(7,i)
         numdens(6,2,i) = xmol(9,i)
         numdens(7,1,i) = xamol(8,i)
         numdens(7,2,i) = xmol(10,i)
      enddo

c*****Read in the names of molecules to be used in molecular equilibrium
      if (ipr(2) .ne. 0) then
         read (nfmodel,208) list
         list2 = list(11:)
         read (list2,*) nmol
         read (nfmodel,*) (amol(i),i=1,nmol)                                 
      endif

c*****SPECIAL NEEDS: for NEWMARCS models, to convert kaprefs to our units
      if (modtype .eq. 'NEWMARCS  ') then
         do i=1,ntau
            kapref(i) = kaprefmass(i)*rho(i)
         enddo
c     SPECIAL NEEDS: for KURUCZ models, to create the optical depth array,
c     and to convert kaprefs to our units
      elseif (modtype .eq. 'KURUCZ    ') then
         first = rhox(1)*kaprefmass(1)
         tottau = rinteg(rhox,kaprefmass,tauref,ntau,first) 
         tauref(1) = first
         do i=2,ntau
            tauref(i) = tauref(i-1) + tauref(i)
         enddo
         do i=1,ntau
            kapref(i) = kaprefmass(i)*rho(i)
         enddo
c     SPECIAL NEEDS: for BEGN models, to convert kaprefs to our units
      elseif (modtype .eq. 'BEGN      ') then
         do i=1,ntau                                                    
            kapref(i) = kaprefmass(i)*rho(i)
         enddo
c     SPECIAL NEEDS: for KURTYPE models, to create internal kaprefs,
c     and to compute taurefs from the kaprefs converted to mass units
      elseif (modtype .eq. 'KURTYPE   ') then
         call opacit (1,wavref)
         do i=1,ntau                                                    
            kaprefmass(i) = kapref(i)/rho(i)
         enddo
         first = rhox(1)*kaprefmass(1)
         tottau = rinteg(rhox,kaprefmass,tauref,ntau,first) 
         tauref(1) = first
         do i=2,ntau
            tauref(i) = tauref(i-1) + tauref(i)
         enddo
c     SPECIAL NEEDS: for NEWMARCS models, to convert kaprefs to our units
      elseif (modtype .eq. 'KUR-PADOVA') then
         do i=1,ntau
            kapref(i) = kaprefmass(i)*rho(i)
         enddo
c
c
c     SPECIAL NEEDS: for NEXTGEN models, to convert kaprefs to our units
      elseif (modtype .eq. 'NEXTGEN   ') then
         do i=1,ntau
            kapref(i) = kaprefmass(i)*rho(i)
         enddo
c
c
c     SPECIAL NEEDS: for generic models, to create internal kaprefs,
      elseif (modtype .eq. 'GENERIC   ') then
         call opacit (1,wavref)
      endif

c*****Convert from logarithmic optical depth scales, or vice versa.
c     xref will contain the log of the tauref
      if(tauref(1) .lt. 0.) then
         do i=1,ntau                                                    
            xref(i) = tauref(i)
            tauref(i) = 10.0**xref(i)                                        
         enddo
      else
         do i=1,ntau                                                    
            xref(i) = dlog10(tauref(i))                                        
         enddo
      endif

c*****Locate the atmosphere level where tauref is near 0.5
      do i=1,ntau
         if (tauref(i) .ge. 0.5) go to 180
      enddo
180   jtau5 = i

c*****Write information to output
      call out (1)
      call out (8)

      return

      end                                                                
