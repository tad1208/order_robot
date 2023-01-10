*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             Screenshot
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets
# Library    RPA.Robocorp.Vault


*** Variables ***
${URL_LOGIN}            https://robotsparebinindustries.com
${URL_ORDER_ROBOT}      https://robotsparebinindustries.com/#/robot-order
${CSV_FILE}             https://robotsparebinindustries.com/orders.csv
${DOWNLOAD_PATH}        ${OUTPUT DIR}${/}output${/}orders.csv


*** Tasks ***
Test
    Test Vault

Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    # ${row}=    Get Table Row    ${orders}    1
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        Store robot order to a PDF file    ${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    url
    ${URL_ORDER_ROBOT}=    Set Variable    ${secret}[url_order_robot]
    Open Available Browser    ${URL_ORDER_ROBOT}

Get orders
    # Download order file from: https://robotsparebinindustries.com/orders.csv, overwrite = True
    # You need your custom Get orders keyword to return the result. See the Robot Framework keywords article. There's a section about returning things from a keyword.
    # Learn about assigning variables to assign the returned orders to a variable.
    Input Csv Url Dialogs
    Download    ${CSV_FILE}    ${DOWNLOAD_PATH}    overwrite=True
    ${orders}=    Read table from CSV    ${DOWNLOAD_PATH}    dialect=excel    header=True
    RETURN    ${orders}

Close the annoying modal
    Click Button When Visible    //button[@class='btn btn-dark']

Fill the form
    [Arguments]    ${row}
    # Log    ${row['Order number']}
    Select From List By Value    //select[@id="head"]    ${row['Head']}
    Select Radio Button    body    ${row['Body']}
    Input Text    //input[@class='form-control'][@type='number']    ${row['Legs']}
    Input Text    //input[@class='form-control'][@type='text']    ${row['Address']}

Preview the robot
    Click Button    //button[@id='preview']

Submit the order
    WHILE    ${True}
        Click Button    //button[@id='order']
        ${receipts}=    Get WebElements    //div[@id='receipt']
        ${receipts_no}=    Get Length    ${receipts}
        IF    ${receipts_no} > 0            BREAK
    END

Store robot order to a PDF file
    [Arguments]    ${order_number}
    ${pdf_path}=    Set Variable    ${OUTPUT DIR}${/}output${/}pdfs${/}${order_number}.pdf
    ${receipt_html}=    Get Element Attribute    //div[@id='receipt']    outerHTML
    # Log To Console    ${receipt_html}
    Html To Pdf    ${receipt_html}    ${pdf_path}
    Screenshot    //div[@id='robot-preview-image']    ${OUTPUT DIR}${/}output${/}robot_img.png
    ${robot_imgs}=    Create List    ${OUTPUT DIR}${/}output${/}robot_img.png
    Add Files To Pdf    ${robot_imgs}    ${pdf_path}    append=${True}
    RETURN    ${pdf_path}

Go to order another robot
    Click Button    //button[@id='order-another']

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT DIR}${/}output${/}pdfs    ${OUTPUT DIR}${/}output${/}receipts.zip

Input Csv Url Dialogs
    Add heading    CSV File
    Add text input    csv_url    label=CSV URL
    ${result}=    Run dialog
    ${CSV_FILE}=    Set Variable    ${result.csv_url}

Test Vault
    ${secret}=    Get Secret    url
    Log    ${secret}[url_login]
    Log    ${secret}[url_order_robot]
