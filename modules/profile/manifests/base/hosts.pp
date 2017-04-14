class profile::base::hosts(
   Hash $list,
)
{
  $list.each |$host, $key| {
    host{$host:
      * => $key,
    }
  }
}
