local type, tostring, pairs = _G.type, _G.tostring, _G.pairs

local CONF = {
	indent = '  ',
	recursive = function( tbl, _ )
		return ( '%q' ):format( 'recursive ' .. tostring( tbl ))
	end,
	array = '{%s}',
	arraysep = ', ',
	arraylimit = 120,
	table = '{%s}',
	tablesep = ',\n',
	keyvaluesep = ' = ',
	keysort = table.sort,
	keyid = '%s',
	keygeneric = '[%s]',
}

local function str( v, conf, indent, tables )
	conf = conf or CONF
	local T = type( v )
	if T == 'string' then
		return ( "%q" ):format( v )
	elseif T == 'number' or T == 'boolean' or T == 'nil' then
		return tostring( v )
	elseif T == 'table' then
		indent = indent or 0
		tables = tables or {}
		local indent_ = conf.indent or CONF.indent
		local indentation = indent_:rep( indent + 1 )
		if tables[v] then
			return (conf.recursive or CONF.recursive)( v )
		end
		tables[v] = true
		local nkeys = 0
		for _ in pairs( v ) do
			nkeys = nkeys + 1
		end
		local buffer = {}
		local tables_ = setmetatable( {}, {__index = tables} )
		if nkeys == #v then
			for i = 1, #v do
				buffer[i] = str( v[i], conf, indent, tables_ )
			end
			local s = table.concat( buffer, conf.arraysep or CONF.arraysep)
			local array, arraylimit = conf.array or CONF.array, conf.arraylimit or CONF.arraylimit
			if #s <= arraylimit then
				for k, w in pairs( tables_ ) do
					tables[k] = w
				end
				return array:format( s )
			else
				local tablesep = conf.tablesep or CONF.tablesep
				for i = 1, #v do
					buffer[i] = indentation .. str( v[i], conf, indent + 1, tables )
				end
				return array:format( '\n' .. table.concat( buffer, tablesep ) .. '\n' .. indent_:rep( indent ))
			end
		else
			local keys = {}
			for k in pairs( v ) do
				keys[#keys+1] = k
			end
			local keysort = conf.keysort or CONF.keysort
			if keysort then
				keysort( keys )
			end
			local kvsep, keygeneric = conf.keyvaluesep or CONF.keyvaluesep, conf.keygeneric or CONF.keygeneric
			for i = 1, #keys do
				local k = keys[i]
				local w = v[k]
				local line
				if type( k ) == 'string' and k:match( '^[%a_][%w_]*$' ) then
					line = (conf.keyid or CONF.keyid):format( k ) .. kvsep .. str( w, conf, indent + 1, tables )
				else
					line = keygeneric:format( str( k, conf, indent + 1, tables )) .. kvsep .. str( w, conf, indent + 1, tables )
				end
				buffer[#buffer+1] = indentation .. line
			end
			local table_, tablesep = conf.table or CONF.table, conf.tablesep or CONF.tablesep
			return table_:format( '\n' .. table.concat( buffer, tablesep ) .. '\n' .. indent_:rep( indent ))
		end
	else
		return ( "%q" ):format( tostring( v ))
	end
end

return str
