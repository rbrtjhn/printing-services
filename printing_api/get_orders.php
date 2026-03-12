<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

include "connection.php";

// This grabs all orders, putting the newest ones at the top
$sql = "SELECT * FROM tbl_orders ORDER BY order_date DESC";
$stmt = $conn->prepare($sql);
$stmt->execute();
$result = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo json_encode($result);
?>