set(expect
  query
  query/client-foo
  query/client-foo/query.json
  reply
  reply/index-[0-9.T-]+.json
  reply/toolchains-v1-[0-9a-f]+.json
  )
check_api("^${expect}$")

check_python(toolchains-v1 index)
