class profile::base::hosts(
  Hash $list = lookup('::profile::base::hosts::list', Hash, 'hash', {}),
)
{
  $list.each |$host, $values| {
    host { $host:
      * => $values,
    }
  }
}
