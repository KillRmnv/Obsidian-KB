![[Pasted image 20260114205034.png]]
sufficientFunds.await()--разблокирует bankLock
signalAll() говорит остальным тредам на await() проснуться.При выходе из awit() захватывается bankLock.lock()(выстраивается очередь)
![[Pasted image 20260114205523.png]]
![[Pasted image 20260114205653.png]]

гыг, await() может проснуться в любой момент, поэтому цикл while обязателен