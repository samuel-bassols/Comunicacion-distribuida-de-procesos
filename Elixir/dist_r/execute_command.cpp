#include <RInside.h>                    // for the embedded R via RInside
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
using namespace std;

string USERPWD="sftpuser:password2023";
string DIR_IN="sftp://sftpuser@192.168.1.34/sftpuser/in/";
string DIR_OUT="sftp://sftpuser@192.168.1.34/sftpuser/out/";
string LIB="./r_libraries.R";


int main(int argc, char *argv[]) {

    string token=argv[1];
    //cout << token;
    string in_data_file=DIR_IN+token+".rds";
    string out_data_file=DIR_OUT+token+".rds";
    string out_error_file=DIR_OUT+token+".txt";
    string lines_file=DIR_IN+token+".txt";
    string temp_file="temp";
    string temp_ext=".rds";
    

    RInside R(argc, argv);              // create an embedded R instance 
    R["token"] = token;	// assign token to the object in the R instance
    R["out_d"] = out_data_file;	// data_out in R
    R["error_d"] = out_error_file;	// data_out in R
    R["in_d"] = in_data_file;	// data_in in R
    R["lines_file"] = lines_file; //lines to execute
    R["userpass"] = USERPWD; //user and password
    R["temp"]=temp_file;
    R["ext"]=temp_ext;
    R["lib"]=LIB;
    try {
      R.parseEvalQ("library(RCurl)");
      R.parseEvalQ("source(lib)");
      //load data
      R.parseEvalQ("rawRDS <- as.raw(getBinaryURL(in_d, userpwd = userpass))");
      R.parseEvalQ("objectRDS<-readRDS(gzcon(rawConnection(rawRDS)))"); 
      R.parseEvalQ("output<-list2env(objectRDS,globalenv())");
      //lines to exeute
      R.parseEvalQ("lines<-getURL(lines_file, userpwd = userpass)");
      //execute
      string try_eval="tryCatch({"
        "fout<-eval(parse(text=substr(lines,1,nchar(lines)-2)))},"
        "error = function(e){"
        "e<-as.character(e);"
        "ftpUpload(I(e),error_d, userpwd = userpass);"
        " stop()})";
      R.parseEvalQ(try_eval);         
      R.parseEvalQ("fil <- tempfile(temp, fileext = ext)"); 
      R.parseEvalQ("saveRDS(fout,file=fil)");
      R.parseEvalQ("ftpUpload(fil,out_d, userpwd = userpass)");
      

    } catch(std::exception& ex) {
        std::cerr << "Exception caught: " << ex.what() << std::endl;
        exit(1);
    } catch(...) {
        //std::cerr << "Unknown exception caught" << std::endl;
        exit(1);
    }

    exit(0);
}
