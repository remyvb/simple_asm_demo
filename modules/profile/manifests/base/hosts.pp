class profile::base::hosts(
   Hash $list,
)
{
  $list.each |$host, $values| {
    host { $host:
      * => $values,
    }
  }
}
