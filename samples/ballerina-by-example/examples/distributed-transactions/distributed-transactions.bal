import ballerina.data.sql;

function main (string[] args) {
    //Create an endpoint for the first database named testdb1. Since this endpoint is
    //participated in a distributed transaction, the isXA property of the
    //sql:ClientConnector should be true.
    endpoint<sql:ClientConnector> testDB1 {
        create sql:ClientConnector(
        sql:DB.MYSQL, "localhost", 3306, "testdb1", "root", "root",
        {maximumPoolSize:1, isXA:true});
    }
    //Create an endpoint for the second database named testdb2. Since this endpoint is
    //participated in a distributed transaction, the isXA property of the
    //sql:ClientConnector should be true.
    endpoint<sql:ClientConnector> testDB2 {
        create sql:ClientConnector(
        sql:DB.MYSQL, "localhost", 3306, "testdb2", "root", "root",
        {maximumPoolSize:1, isXA:true});
    }
    //Create the table named CUSTOMER in the first database.
    int ret = testDB1.update("CREATE TABLE CUSTOMER (ID INT AUTO_INCREMENT PRIMARY KEY,
                                    NAME VARCHAR(30))", null);
    println("CUSTOMER table create status in first DB:" + ret);
    //Create the table named SALARY in the second database.
    ret = testDB2.update("CREATE TABLE SALARY (ID INT, VALUE FLOAT)", null);
    println("SALARY table create status in second DB:" + ret);

    boolean transactionSuccess = false;
    //Begins the transaction.
    transaction {
        //This is the first action participate in the transaction which insert customer
        //name to the first DB and get the generated key.
        var insertCount, generatedID = testDB1.updateWithGeneratedKeys("INSERT INTO
                                     CUSTOMER(NAME) VALUES ('Anne')", null, null);
        var returnedKey, _ = <int>generatedID[0];
        println("Inserted count to CUSTOMER table:" + insertCount);
        println("Generated key for the inserted row:" + returnedKey);
        //This is the second action participate in the transaction which insert the
        //salary info to the second DB along with the key generated in the first DB.
        sql:Parameter para1 = {sqlType:sql:Type.INTEGER, value:returnedKey};
        sql:Parameter[] params = [para1];
        ret = testDB2.update("INSERT INTO SALARY (ID, VALUE) VALUES (?, 2500)", params);
        println("Inserted count to SALARY table:" + ret);

        transactionSuccess = true;
    } failed {
        println("Transaction failed");
        transactionSuccess = false;
    }
    if (transactionSuccess) {
        println("Transaction committed");
    }
    //Drop the tables created for this sample.
    ret = testDB1.update("DROP TABLE CUSTOMER", null);
    println("CUSTOMER table drop status:" + ret);
    ret = testDB2.update("DROP TABLE SALARY", null);
    println("SALARY table drop status:" + ret);

    //Close the connection pool.
    testDB1.close();
    testDB2.close();
}
