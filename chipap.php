<?php

$config = array(
  'admin_user' => 'admin',
  'admin_pass' => '$2y$10$YKIyWAmnQLtiJAy6QgHQ.eCpY4m.HCEbiHaTgN6.acNC6bDElzt.i'
);

/*
if(file_exists(RASPI_CONFIG.'/chipap.auth')) {
    if ( $auth_details = fopen(RASPI_CONFIG.'/chipap.auth', 'r') ) {
      $config['admin_user'] = trim(fgets($auth_details));
      $config['admin_pass'] = trim(fgets($auth_details));
      fclose($auth_details);
    }
}
 */
?>
