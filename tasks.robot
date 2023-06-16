*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    OperatingSystem
Library    Screenshot
Library    RPA.Archive

*** Variables ***
${URL_web}=   https://robotsparebinindustries.com/#/robot-order
${CSV_file}=    https://robotsparebinindustries.com/orders.csv
${receipt_directory}=       ${OUTPUT_DIR}${/}receipts${/}
${image_directory}=         ${OUTPUT_DIR}${/}images${/}
${zip_directory}=           ${OUTPUT_DIR}${/}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    Get orders
    Create the ZIP
    [Teardown]    Delete original images
    Log out and close the browser

*** Keywords ***
Open the robot order website
    Open Available Browser    ${URL_web}

Close the annoying modal
    Wait Until Element Is Visible    class:alert-buttons
    Click Button    OK

Make order
    Click Button    order
    Wait Until Element Is Visible    receipt

Fill the form for one person
    [Arguments]    ${orders}
    Select From List By Index    head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    Click Button    preview
    Wait Until Keyword Succeeds    1 min    3 sec    Make order
    
Save order details
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    receipt
    Set Local Variable    ${receipt_filename}    ${receipt_directory}receipt_${order_number}.pdf
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    content=${receipt_html}    output_path=${receipt_filename}

    Wait Until Element Is Visible    id:robot-preview-image
    Set Local Variable    ${image_filename}    ${image_directory}robot_${order_number}.png
    Screenshot    id:robot-preview-image    ${image_filename}
    Combine receipt with robot image to a PDF    ${receipt_filename}    ${image_filename}

Combine receipt with robot image to a PDF
    [Arguments]    ${receipt_filename}    ${image_filename}

    Open PDF    ${receipt_filename}
    @{pseudo_file_list}=    Create List
    ...    ${receipt_filename}
    ...    ${image_filename}:align=center

    Add Files To PDF    ${pseudo_file_list}    ${receipt_filename}    ${False}
    Close Pdf    ${receipt_filename}

Go to order another robot
    Click Button    order-another
    Close the annoying modal

Get orders
    Download    ${CSV_file}    overwrite=${True}
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${row}    IN    @{orders}
        Log    ${row}
        Fill the form for one person    ${row}
        Save order details    ${row}[Order number]
        Go to order another robot
    END

Create the ZIP
    ${zip_file_name}=    Set Variable    ${zip_directory}/Robots.zip
    Archive Folder With Zip
    ...    ${receipt_directory}
    ...    ${zip_file_name}

Log out and close the browser
    Close Browser

Delete original images
    Empty Directory    ${image_directory}
    Empty Directory    ${receipt_directory}