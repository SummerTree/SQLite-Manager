#ifndef SQLITEDB_H
#define SQLITEDB_H

#include <stdlib.h>
//#include <qstringlist.h>
//#include <qmap.h>
//#include <q3valuelist.h>
//#include <qobject.h>
//#include "sqllogform.h"
#include <map>
#include <vector>
#include <string>
#include "sqlite3.h"
#include "sqlitebrowsertypes.h"

using namespace std;

#define MAX_DISPLAY_LENGTH 255

enum
{
    kLogMsg_User,
    kLogMsg_App
};

enum
{
    kEncodingUTF8,
    kEncodingLatin1,
    kEncodingNONE
};

static string applicationName = string("SQLite Database Browser");
static string applicationIconName = string("icone16.png");
static string aboutText = string("Version 2.0\n\nSQLite Database Browser is a freeware, public domain, open source visual tool used to create, design and edit database files compatible with SQLite 3.x.\n\nIt has been developed originally by Mauricio Piacentini from Tabuleiro Producoes. \n\nIn the spirit of the original SQLite source code, the author disclaims copyright to this source code.");


typedef map<int, class DBBrowserField> fieldMap;
typedef map<string, class DBBrowserTable> tableMap;
typedef map<string, class DBBrowserIndex> indexMap;
typedef map<int, int> rowIdMap;

typedef vector<vector<string>> rowList;
typedef map<int, string> resultMap;

class DBBrowserField
{
public:
    DBBrowserField() : name( "" ) { }
    DBBrowserField( const string& wname,const string& wtype )
    : name( wname), type( wtype )
    { }
    string getname() const { return name; }
    string gettype() const { return type; }
private:
    string name;
    string type;
};

class DBBrowserIndex
{
public:
    DBBrowserIndex() : name( "" ) { }
    DBBrowserIndex( const string& wname,const string& wsql )
    : name( wname), sql( wsql )
    { }
    string getname() const { return name; }
    string getsql() const { return sql; }
private:
    string name;
    string sql;
};


class DBBrowserTable
{
public:
    DBBrowserTable() : name( "" ) { }
    DBBrowserTable( const string& wname,const string& wsql )
    : name( wname), sql( wsql )
    { }
    
    void addField(int order, const string& wfield,const string& wtype);
    
    string getname() const { return name; }
    string getsql() const { return sql; }
    fieldMap fldmap;
private:
    string name;
    string sql;
};


class DBBrowserDB
{
public:
    DBBrowserDB (): _db( 0 ) , hasValidBrowseSet(false), curEncoding(kEncodingUTF8) {}
    ~DBBrowserDB (){}
    bool open ( const string & db);
    bool create ( const string & db);
    void close ();
    bool compact ();
    bool setRestorePoint();
    bool save ();
    bool revert ();
    bool dump( const string & filename);
    bool reload( const string & filename, int * lineErr);
    bool executeSQL ( const string & statement);
    bool executeSQLDirect ( const string & statement);
    void updateSchema() ;
    bool addRecord();
    bool deleteRecord(int wrow);
    bool updateRecord(int wrow, int wcol, const string & wtext);
    bool browseTable( const string & tablename );
    vector<string> getTableFields(const string & tablename);
    vector<string> getTableTypes(const string & tablename);
    vector<string> getTableNames();
    vector<string> getIndexNames();
    resultMap getFindResults( const string & wstatement);
    int getRecordCount();
    bool isOpen();
    void setDirty(bool dirtyval);
    void setDirtyDirect(bool dirtyval);
    bool getDirty();
    void logSQL(string statement, int msgtype);
    void setEncoding( int encoding );
    void setDefaultNewData( const string & data );
    const char * GetEncodedQString( const string & input);
    const char * GetDecodedQString( const string & input);
    sqlite3 * _db;
    
    
	vector<string> decodeCSV(const string & csvfilename, char sep, char quote,  int maxrecords, int * numfields);
    
	tableMap tbmap;
	indexMap idxmap;
	rowIdMap idmap;
	
	rowList browseRecs;
	vector<string> browseFields;
	bool hasValidBrowseSet;
	string curBrowseTableName;
	string lastErrorMessage;
	string curDBFilename;
    int curEncoding;
    string curNewData;
	
//	sqlLogForm * logWin;
	
    
private:
    bool dirty;
	void getTableRecords( const string & tablename );
	
	
};

#endif
