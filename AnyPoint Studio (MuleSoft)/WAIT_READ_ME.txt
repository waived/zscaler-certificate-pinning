For this certificate pinning method, you may be asked to enter in a password once or
more than once. This is because Java and Java-based compilers and IDEs make use of a
binary file called "cacerts" which requires a password to be modified.

This is NOT your account password nor the password for the local/system administrator.

Unless you or your organization has changed the password, the password is literally "changeit"
without the double-quotes.

=========================================================================================================

In addition, AnyPoint often makes third-party API calls to specific domains on the internet.
These needs to be whitelisted.

MuleSoft:
    MuleSoft Maven repositories and Connectors update site => 
        https://repository.mulesoft.org (/*)
    Anypoint Studio provided update sites => 
        https://studio.mulesoft.org.s3.amazonaws.com (/*)
    Eclipse libraries and Eclipse update sites => 
        http://download.eclipse.org (/eclipse/updates/*)
    Anypoint Platform services: CloudHub, Exchange, Core Services => 
        https://*.anypoint.mulesoft.com (/*)
    All assets downloaded from Exchange => 
        https://exchange2-asset-manager-kprod.s3.amazonaws.com (/*) 
        https://exchange2-asset-manager-kprod-eu.s3.eu-central-1.amazonaws.com (/*)
    Resources for API Portals => 
        https://exchange2-file-upload-service-kprod.s3.amazonaws.com (/*)

Third-Party:
    Eclipse =>
        https://download.eclipse.org/eclipse/updates (/*)
    Maven =>
        https://repo.maven.apache.org/maven2 (/*)
        https://repo1.maven.org/maven2 (/*)
