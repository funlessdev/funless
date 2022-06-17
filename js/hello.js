function main(params) {
	let name = params.name || "World"
	return { payload: `Hello ${name}!` }
}
