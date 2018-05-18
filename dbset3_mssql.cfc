component extends='dbset3' {
	private boolean function useOffsetFetchSyntax() {
		// MSSQL has a weird syntax instead of normal OFFSET/LIMIT.
		return true;
	}
}