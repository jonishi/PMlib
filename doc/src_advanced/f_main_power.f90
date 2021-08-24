
program main
	include 'mpif.h'
	parameter(msize=500)
	real(kind=8), allocatable :: a(:,:),b(:,:),c(:,:)
	real(kind=8) :: dinit, dflop, dbyte
	integer nWatch
	allocate (a(msize,msize), b(msize,msize), c(msize,msize), stat=istat)
	if (istat.ne.0) then
		write(*,*) "*** Allocate() failed."
		stop
	endif

	call MPI_Init(ierr )
	call MPI_Comm_rank( MPI_COMM_WORLD, myid, ierr )
	call MPI_Comm_size( MPI_COMM_WORLD, ncpus, ierr )
	write(6,'(a,i3,a)') "fortran <main> started process:", myid

	n=msize
	nWatch=4
	call f_pm_initialize (nWatch)

	call f_pm_start ("Initial-section")
	call subinit (msize,n,a,b,c)
	call f_pm_stop ("Initial-section")
!cx
    Max_power_knob=5
    do i=0,Max_power_knob-1
    call f_pm_getpowerknob (i,kval)
    if(myid.eq.0) write(*,'(a,2i6)') "preset value of power knob:", i, kval
    enddo
    do i=0,Max_power_knob-1
    kval=1;
    if(i.eq.0) kval=2200;
    if(i.eq.1) kval=5;
    call f_pm_setpowerknob (i,kval)
    if(myid.eq.0) write(*,'(a,2i6)') "preset value of power knob:", i, kval
    enddo
!cx
	call f_pm_start ("Kernel-Fast")
	call submtxm (msize,n,dflop,a,b,c)
	call f_pm_stop ("Kernel-Fast")
	call f_pm_report ("")

	call MPI_Finalize( ierr )
end program

subroutine subinit (msize,n,a,b,c)
	real(kind=8) :: a(msize,msize), b(msize,msize), c(msize,msize)
	write(6,'(a,i3,a)') " starting  <subinit>"
	!$omp parallel
	!$omp do
	do j=1, n
	do i=1, n
	a(i,j)=sin(real(i)/real(n))
	b(i,j)=cos(real(i)/real(n))
	end do
	end do
	!$omp end do
	!$omp end parallel
	write(6,'(a,i3,a)') " returns   <subinit>"
	return
end

subroutine submtxm (msize,n,dflop,a,b,c)
	real(kind=8) :: a(msize,msize), b(msize,msize), c(msize,msize)
	real(kind=8) :: dflop
	real(kind=8) :: x
	write(6,'(a,i3,a)') " starting  <submtxm>"
	dflop=2.0*dble(n)**3
	!$omp parallel
	!$omp do private(x)
	do j=1, n
	do i=1, n
	x=0
	do k=1, n
	x=x+a(i,k)*b(k,j)
	end do
	c(i,j) = x
	end do
	end do
	!$omp end do
	!$omp end parallel
	write(6,'(a,i3,a)') " returns   <submtxm>"
	return
end

