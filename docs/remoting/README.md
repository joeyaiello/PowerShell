# Remoting with PowerShell 6.0

PowerShell 6.0 supports two transports for the PowerShell Remoting Protocol (PSRP), the protocol used by `*-PSSession` cmdlets:

* **WSMan**: this is the traditional transport for PSRP used by Windows PowerShell 2.0 through 5.1.
  The implementation of WSMan on Windows is called WinRM.
  You can learn more about WinRM [on MSDN](https://msdn.microsoft.com/en-us/library/aa384426(v=vs.85).aspx)
* **SSH**: Secure SHell, or SSH, is a protocol that provides a secure channel used for terminal remoting, file transfers, port forwarding and more.
  PSRP over SSH takes advantage of the subsystem feature in OpenSSH to allow PSRP to be a secure SSH channel.


