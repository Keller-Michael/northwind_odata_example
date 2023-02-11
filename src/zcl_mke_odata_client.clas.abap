CLASS zcl_mke_odata_client DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    METHODS constructor RAISING cx_web_http_client_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_customer,
             CustomerID   TYPE string,
             CompanyName  TYPE string,
             ContactName  TYPE string,
             ContactTitle TYPE string,
             Address      TYPE string,
             City         TYPE string,
             region       TYPE string,
             postalcode   TYPE string,
             country      TYPE string,
             phone        TYPE string,
             fax          TYPE string,
           END OF ty_customer.

    TYPES ty_customers TYPE TABLE OF ty_customer WITH KEY customerid.

    DATA http_client TYPE REF TO if_web_http_client.

    METHODS get_single_customer
      IMPORTING
        console TYPE REF TO if_oo_adt_classrun_out
      RAISING
        cx_web_http_client_error.

    METHODS deserialize_customer_json
      IMPORTING
        json          TYPE string
      RETURNING
        VALUE(result) TYPE zcl_mke_odata_client=>ty_customer.

    METHODS get_all_customers
      IMPORTING
        console TYPE REF TO if_oo_adt_classrun_out
      RAISING
        cx_web_http_client_error.

    METHODS deserialize_customers_json
      IMPORTING
        content       TYPE string
      RETURNING
        VALUE(result) TYPE ty_customers.

ENDCLASS.



CLASS zcl_mke_odata_client IMPLEMENTATION.

  METHOD constructor.
    TRY.
        DATA(http_destination) = cl_http_destination_provider=>create_by_url( 'https://services.odata.org' ).
        http_client = cl_web_http_client_manager=>create_by_http_destination( http_destination ).
      CATCH cx_http_dest_provider_error INTO DATA(destination_provider_error).
        RAISE EXCEPTION NEW cx_web_http_client_error( ).
      CATCH cx_web_http_client_error INTO DATA(http_client_error).
        RAISE EXCEPTION NEW cx_web_http_client_error( ).
    ENDTRY.
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    TRY.
        get_single_customer( out ).
        get_all_customers( out ).
      CATCH cx_web_http_client_error INTO DATA(http_client_error).
        out->write( 'Error occurred.' ).
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD get_single_customer.
    DATA customer TYPE ty_customer.

    TRY.
        DATA(request) = http_client->get_http_request(  ).
        request->set_uri_path( i_uri_path = '/V3/Northwind/Northwind.svc/Customers(CustomerID=''ALFKI'')' ).
        request->set_query( '$format=json' ).
        DATA(response) = http_client->execute( i_method = if_web_http_client=>get ).
        DATA(response_content) = response->get_text( ).
      CATCH cx_web_http_client_error INTO DATA(http_client_error).
        RAISE EXCEPTION NEW cx_web_http_client_error( ).
      CATCH cx_web_message_error INTO DATA(message_error).
        RAISE EXCEPTION NEW cx_web_http_client_error( ).
    ENDTRY.

    customer = deserialize_customer_json( response_content ).
    console->write( customer ).
  ENDMETHOD.

  METHOD deserialize_customer_json.
    /ui2/cl_json=>deserialize(
                    EXPORTING
                      json             = json
*                     jsonx            =
                      pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
*                     assoc_arrays     =
*                     assoc_arrays_opt =
*                     name_mappings    =
*                     conversion_exits =
*                     hex_as_base64    =
                    CHANGING
                      data             = result ).
  ENDMETHOD.

  METHOD deserialize_customers_json.
    DATA(json) = match( val  = content
                        pcre = '\[.+\]' ).

    " alternativ way maybe to use class XCO_CP_JSON

    /ui2/cl_json=>deserialize(
                    EXPORTING
                      json             = json
*                     jsonx            =
                      pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
*                     assoc_arrays     =
*                     assoc_arrays_opt =
*                     name_mappings    =
*                     conversion_exits =
*                     hex_as_base64    =
                    CHANGING
                      data             = result ).
  ENDMETHOD.

  METHOD get_all_customers.
    DATA customers TYPE ty_customers.

    TRY.
        DATA(request) = http_client->get_http_request(  ).
        request->set_uri_path( i_uri_path = '/V3/Northwind/Northwind.svc/Customers' ).
        request->set_query( '$format=json' ).
        DATA(response) = http_client->execute( i_method = if_web_http_client=>get ).
        DATA(response_content) = response->get_text( ).
      CATCH cx_web_http_client_error INTO DATA(http_client_error).
        RAISE EXCEPTION NEW cx_web_http_client_error( ).
      CATCH cx_web_message_error INTO DATA(message_error).
        RAISE EXCEPTION NEW cx_web_http_client_error( ).
    ENDTRY.

    customers = deserialize_customers_json( response_content ).
    console->write( customers ).
  ENDMETHOD.

ENDCLASS.
