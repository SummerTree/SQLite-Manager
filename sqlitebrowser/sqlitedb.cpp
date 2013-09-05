#include "sqlitedb.h"
#include "sqlbrowser_util.h"
#include <stdlib.h>
//#include <qregexp.h>
//#include <qimage.h>
//#include <qfile.h>
//#include <q3filedialog.h>
//#include <qmessagebox.h>
//#include <QProgressDialog>

void DBBrowserTable::addField(int order, const string& wfield,const string& wtype)
{
    fldmap[order] = DBBrowserField(wfield,wtype);
}

bool DBBrowserDB::isOpen ( )
{
    return _db!=0;
}

void DBBrowserDB::setDirty(bool dirtyval)
{
    if ((dirty==false)&&(dirtyval==true))
    {
        setRestorePoint();
    }
    dirty = dirtyval;
//    if (logWin)
//    {
//        logWin->msgDBDirtyState(dirty);
//    }
}

void DBBrowserDB::setDirtyDirect(bool dirtyval)
{
    dirty = dirtyval;
//    if (logWin)
//    {
//        logWin->msgDBDirtyState(dirty);
//    }
}

bool DBBrowserDB::getDirty()
{
    return dirty;
}

void DBBrowserDB::setEncoding( int encoding )
{
    curEncoding = encoding;
}

void DBBrowserDB::setDefaultNewData( const string & data )
{
    curNewData = data;
}

const char * DBBrowserDB::GetEncodedQString( const string & input)
{
//    if (curEncoding==kEncodingUTF8) return input.utf8();
//    if (curEncoding==kEncodingLatin1) return input.latin1();
    
    return input.c_str();
}

const char * DBBrowserDB::GetDecodedQString( const string & input)
{
//    if (curEncoding==kEncodingUTF8) return string::fromUtf8(input);
//    if (curEncoding==kEncodingLatin1) return string::fromLatin1(input);
    
    return input.c_str();
}

bool DBBrowserDB::open ( const string & db)
{
    bool ok=false;
    int  err;
    
    if (isOpen()) close();
    
    //try to verify the SQLite version 3 file header
//    QFile dbfile(db);
//    if ( dbfile.open( QIODevice::ReadOnly ) ) {
//        char buffer[16+1];
//        dbfile.readLine(buffer, 16);
//        string contents = string(buffer);
//        dbfile.close();
//        if (!contents.startsWith("SQLite format 3")) {
//            lastErrorMessage = string("File is not a SQLite 3 database");
//            return false;
//        }
//    } else {
//        lastErrorMessage = string("File could not be read");
//        return false;
//    }
    
    lastErrorMessage = string("no error");
    
    err = sqlite3_open(GetEncodedQString(db), &_db);
    if ( err ) {
        lastErrorMessage = sqlite3_errmsg(_db);
        sqlite3_close(_db);
        _db = 0;
        return false;
    }
    
    if (_db){
        if (SQLITE_OK==sqlite3_exec(_db,"PRAGMA empty_result_callbacks = ON;",
                                    NULL,NULL,NULL)){
            if (SQLITE_OK==sqlite3_exec(_db,"PRAGMA show_datatypes = ON;",
                                        NULL,NULL,NULL)){
                ok=true;
                setDirty(false);
            }
            curDBFilename = db;
        }
    }
    return ok;
}

bool DBBrowserDB::setRestorePoint()
{
    if (!isOpen()) return false;
    
    if (_db){
        sqlite3_exec(_db,"BEGIN TRANSACTION RESTOREPOINT;",
                     NULL,NULL,NULL);
        setDirty(false);
    }
    return true;
}

bool DBBrowserDB::save()
{
    if (!isOpen()) return false;
    
    if (_db){
        sqlite3_exec(_db,"COMMIT TRANSACTION RESTOREPOINT;",
                     NULL,NULL,NULL);
        setDirty(false);
    }
    return true;
}

bool DBBrowserDB::revert()
{
    if (!isOpen()) return false;
    
    if (_db){
        sqlite3_exec(_db,"ROLLBACK TRANSACTION RESTOREPOINT;",
                     NULL,NULL,NULL);
        setDirty(false);
    }
    return true;
}

bool DBBrowserDB::create ( const string & db)
{
    bool ok=false;
    
    if (isOpen()) close();
    
    lastErrorMessage = string("no error");
    
    if( sqlite3_open(GetEncodedQString(db), &_db) != SQLITE_OK ){
        lastErrorMessage = sqlite3_errmsg(_db);
        sqlite3_close(_db);
        _db = 0;
        return false;
    }
    
    if (_db){
        if (SQLITE_OK==sqlite3_exec(_db,"PRAGMA empty_result_callbacks = ON;",
                                    NULL,NULL,NULL)){
            if (SQLITE_OK==sqlite3_exec(_db,"PRAGMA show_datatypes = ON;",
                                        NULL,NULL,NULL)){
                ok=true;
                setDirty(false);
            }
            curDBFilename = db;
        }
        
    }
    
    return ok;
}


void DBBrowserDB::close (){
    if (_db)
    {
        if (getDirty())
        {
            string msg = "Do you want to save the changes made to the database file ";
            msg.append(curDBFilename);
            msg.append(" ?");
            if (true)//QMessageBox::question( 0, applicationName ,msg, QMessageBox::Yes, QMessageBox::No)==QMessageBox::Yes)
            {
                save();
            } else {
                //not really necessary, I think... but will not hurt.
                revert();
            }
        }
        sqlite3_close(_db);
    }
    _db = 0;
    idxmap.clear();
    tbmap.clear();
    idmap.clear();
    browseRecs.clear();
    browseFields.clear();
    hasValidBrowseSet = false;
}

bool DBBrowserDB::compact ( )
{
    char *errmsg;
    bool ok=false;
    
    if (!isOpen()) return false;
    
    if (_db){
        save();
        logSQL(string("VACUUM;"), kLogMsg_App);
        if (SQLITE_OK==sqlite3_exec(_db,"VACUUM;",
                                    NULL,NULL,&errmsg)){
            ok=true;
            setDirty(false);
        }
    }
    
    if (!ok){
        lastErrorMessage = string(errmsg);
        return false;
    }else{
        return true;
    }
}

bool DBBrowserDB::reload( const string & filename, int * lineErr)
{
    /*to avoid a nested transaction error*/
    sqlite3_exec(_db,"COMMIT;", NULL,NULL,NULL);
    FILE * cfile = fopen(filename.c_str(), (const char *) "r");
    load_database(_db, cfile, lineErr);
    fclose(cfile);
    setDirty(false);
    if ((*lineErr)!=0)
    {
        return false;
    }
    return true;
}

bool DBBrowserDB::dump( const string & filename)
{
    FILE * cfile = fopen(filename.c_str(), (const char *) "w");
    if (!cfile)
    {
        return false;
    }
    dump_database(_db, cfile);
    fclose(cfile);
    return true;
}

bool DBBrowserDB::executeSQL ( const string & statement)
{
    char *errmsg;
    bool ok=false;
    
    if (!isOpen()) return false;
    
    if (_db){
        logSQL(statement, kLogMsg_App);
        setDirty(true);
        if (SQLITE_OK==sqlite3_exec(_db,GetEncodedQString(statement),
                                    NULL,NULL,&errmsg)){
            ok=true;
        }
    }
    
    if (!ok){
        lastErrorMessage = string(errmsg);
        return false;
    }else{
        return true;
    }
}

bool DBBrowserDB::executeSQLDirect ( const string & statement)
{
    //no transaction support
    char *errmsg;
    bool ok=false;
    
    if (!isOpen()) return false;
    
    if (_db){
        logSQL(statement, kLogMsg_App);
        if (SQLITE_OK==sqlite3_exec(_db,GetEncodedQString(statement),
                                    NULL,NULL,&errmsg)){
            ok=true;
        }
    }
    
    if (!ok){
        lastErrorMessage = string(errmsg);
        return false;
    }else{
        return true;
    }
}


bool DBBrowserDB::addRecord ( )
{
    char *errmsg;
    if (!hasValidBrowseSet) return false;
    if (!isOpen()) return false;
    bool ok = false;
    int fields = browseFields.size();
    string emptyvalue = curNewData;
    
    string statement = "INSERT INTO ";
    statement.append(GetEncodedQString(curBrowseTableName));
    statement.append(" VALUES(");
    for ( int i=1; i<=fields; i++ ) {
        statement.append(emptyvalue);
        if (i<fields) statement.append(", ");
    }
    statement.append(");");
    lastErrorMessage = string("no error");
    if (_db){
        logSQL(statement, kLogMsg_App);
        setDirty(true);
        if (SQLITE_OK==sqlite3_exec(_db,statement.c_str(),NULL,NULL, &errmsg)){
            ok=true;
            //int newrowid = sqlite3_last_insert_rowid(_db);
        } else {
            lastErrorMessage = string(errmsg);
        }
    }
    
    return ok;
}

bool DBBrowserDB::deleteRecord( int wrow)
{
    char * errmsg;
    if (!hasValidBrowseSet) return false;
    if (!isOpen()) return false;
    bool ok = false;
    rowList tab = browseRecs;
    vector<string>& rt = tab[wrow];
    string& rowid = rt[0];
    lastErrorMessage = string("no error");
    
    string statement = "DELETE FROM ";
    statement.append(GetEncodedQString(curBrowseTableName));
    statement.append(" WHERE rowid=");
    statement.append(rowid);
    statement.append(";");
    
    if (_db){
        logSQL(statement, kLogMsg_App);
        setDirty(true);
        if (SQLITE_OK==sqlite3_exec(_db,GetEncodedQString(statement),
                                    NULL,NULL,&errmsg)){
            ok=true;
        } else {
            lastErrorMessage = string(errmsg);
        }
    }
    return ok;
}

bool DBBrowserDB::updateRecord(int wrow, int wcol, const string & wtext)
{
    char * errmsg;
    if (!hasValidBrowseSet) return false;
    if (!isOpen()) return false;
    bool ok = false;
    
    lastErrorMessage = string("no error");
    
    vector<string>& rt = browseRecs[wrow];
    string& rowid = rt[0];
    string& cv = rt[wcol+1];//must account for rowid
    string ct = browseFields.at(wcol);
    
    string statement = "UPDATE ";
    statement.append(GetEncodedQString(curBrowseTableName));
    statement.append(" SET ");
    statement.append(GetEncodedQString(ct));
    statement.append("=");
    
    string wenc = GetEncodedQString(wtext);
    char * formSQL = sqlite3_mprintf("%Q",wenc.c_str());
    statement.append(formSQL);
    if (formSQL) sqlite3_free(formSQL);
    
    statement.append(" WHERE rowid=");
    statement.append(rowid);
    statement.append(";");
    
    if (_db){
        logSQL(statement, kLogMsg_App);
        setDirty(true);
        if (SQLITE_OK==sqlite3_exec(_db,statement.c_str(),
                                    NULL,NULL,&errmsg)){
            ok=true;
            /*update local copy*/
            cv = wtext;
        } else {
            lastErrorMessage = string(errmsg);
        }
    }
    
    return ok;
    
}


bool DBBrowserDB::browseTable( const string & tablename )
{
    vector<string> testFields = getTableFields( tablename );
    
    if (testFields.size()>0) {//table exists
        getTableRecords( tablename );
        browseFields = testFields;
        hasValidBrowseSet = true;
        curBrowseTableName = tablename;
    } else {
        hasValidBrowseSet = false;
        curBrowseTableName = string(" ");
        browseFields.clear();
        browseRecs.clear();
        idmap.clear();
    }
    return hasValidBrowseSet;
}
/*
 atoi( str.c_str() )
 you can use
 
 std::stoi( str )
 */
void DBBrowserDB::getTableRecords( const string & tablename )
{
    sqlite3_stmt *vm;
    const char *tail;
    
    int ncol;
    vector<string> r;
    // char *errmsg;
    int err=0;
    // int tabnum = 0;
    browseRecs.clear();
    idmap.clear();
    lastErrorMessage = string("no error");
    
    string statement = "SELECT rowid, *  FROM ";
    statement.append( GetEncodedQString(tablename) );
    statement.append(" ORDER BY rowid; ");
    //qDebug(statement);
    logSQL(statement, kLogMsg_App);
    err=sqlite3_prepare(_db,statement.c_str(), -1,
                        &vm, &tail);
    if (err == SQLITE_OK){
        int rownum = 0;
        
        while ( sqlite3_step(vm) == SQLITE_ROW ){
            r.clear();
            ncol = sqlite3_data_count(vm);
            for (int e=0; e<ncol; e++){
                char * strresult = 0;
                string rv;
                strresult = (char *) sqlite3_column_text(vm, e);
                rv = string(strresult?:"");
                r.push_back(rv);//r << GetDecodedQString(rv);
                if (e==0){
//                    idmap[rownum] =atoi(rv.c_str());
                    idmap[atoi(rv.c_str())] = rownum;
                    rownum++;
                }
            }
            browseRecs.push_back(r);//browseRecs.append(r);
        }
        
        sqlite3_finalize(vm);
    }else{
        lastErrorMessage = string ("could not get fields");
    }
}

resultMap DBBrowserDB::getFindResults( const string & wstatement)
{
    sqlite3_stmt *vm;
    const char *tail;
    
    int ncol;
    
    //   char *errmsg;
    int err=0;
    resultMap res;
    lastErrorMessage = string("no error");
    string encstatement = GetEncodedQString(wstatement);
    logSQL(encstatement, kLogMsg_App);
    err=sqlite3_prepare(_db,encstatement.c_str(),encstatement.size(),
                        &vm, &tail);
    if (err == SQLITE_OK){
        int rownum = 0;
        int recnum = 0;
        string r;
        while ( sqlite3_step(vm) == SQLITE_ROW ){
            ncol = sqlite3_data_count(vm);
            for (int e=0; e<ncol; e++){
                char * strresult = 0;
                strresult = (char *) sqlite3_column_text(vm, e);
                r = string(strresult);
                if (e==0){
                    rownum = atoi(r.c_str());//r.toInt();
                    rowIdMap::iterator mit = idmap.find(rownum);
                    recnum = mit->second;//recnum = *mit;
                }
            }
            //TOTO:FIX
//            res.insert(recnum, GetDecodedQString(r));

        }
        
        sqlite3_finalize(vm);
    }else{
        lastErrorMessage = string(sqlite3_errmsg(_db));
    }
    return res;
}


vector<string> DBBrowserDB::getTableNames()
{
    tableMap::iterator it;
    tableMap tmap = tbmap;
    vector<string> res;
    
    for ( it = tmap.begin(); it != tmap.end(); ++it ) {
//        res.append( it.data().getname() );
        res.push_back(it->second.getname());
    }
    
    return res;
}

vector<string> DBBrowserDB::getIndexNames()
{
    indexMap::iterator it;
    indexMap tmap = idxmap;
    vector<string> res;
    
    for ( it = tmap.begin(); it != tmap.end(); ++it ) {
//        res.append( it.data().getname() );
        res.push_back(it->second.getname());
    }
    
    return res;
}

vector<string> DBBrowserDB::getTableFields(const string & tablename)
{
    tableMap::iterator it;
    tableMap tmap = tbmap;
    vector<string> res;
    
    for ( it = tmap.begin(); it != tmap.end(); ++it ) {
        if (tablename.compare(it->second.getname())==0 ){
            fieldMap::iterator fit;
            fieldMap fmap = it->second.fldmap;
            
            for ( fit = fmap.begin(); fit != fmap.end(); ++fit ) {
//                res.append( fit.data().getname() );
                res.push_back(fit->second.getname());
            }
        }
    }
    return res;
}

vector<string> DBBrowserDB::getTableTypes(const string & tablename)
{
    tableMap::iterator it;
    tableMap tmap = tbmap;
    vector<string> res;
    
    for ( it = tmap.begin(); it != tmap.end(); ++it ) {
        if (tablename.compare(it->second.getname())==0 ){
            fieldMap::iterator fit;
            fieldMap fmap = it->second.fldmap;
            
            for ( fit = fmap.begin(); fit != fmap.end(); ++fit ) {
//                res.append( fit.data().gettype() );
                res.push_back(fit->second.gettype());
            }
        }
    }
    return res;
}

int DBBrowserDB::getRecordCount()
{
    return browseRecs.size();
}

void DBBrowserDB::logSQL(string statement, int msgtype)
{
//    if (logWin)
//    {
//        /*limit log message to a sensible size, this will truncate some binary messages*/
//        uint loglimit = 300;
//        if ((statement.length() > loglimit)&&(msgtype==kLogMsg_App))
//        {
//            bool binary;
//            for (int i = 0; i < statement.size(); i++)
//            {
//                if (statement.at(i) < 32)
//                {
//                    binary = TRUE;
//                }
//            }
//            if (binary)
//            {
//                statement.truncate(32);
//                statement.append("... <string too wide to log, probably contains binary data> ...");
//            }
//        }
//        logWin->log(statement, msgtype);
//    }
}


void DBBrowserDB::updateSchema( )
{
    // qDebug ("Getting list of tables");
    sqlite3_stmt *vm;
    const char *tail;
    vector<string> r;
    int err=0;
    int idxnum =0;
    int tabnum = 0;
    
    idxmap.clear();
    tbmap.clear();
    
    lastErrorMessage = string("no error");
    string statement = "SELECT name, sql "
    "FROM sqlite_master "
    "WHERE type='table' ;";
    
    err=sqlite3_prepare(_db, statement.c_str(),statement.size(),
                        &vm, &tail);
    if (err == SQLITE_OK){
        logSQL(statement, kLogMsg_App);
        while ( sqlite3_step(vm) == SQLITE_ROW ){
            string  val1, val2;
            val1 = string((const char *) sqlite3_column_text(vm, 0)?:"");
            val2 = string((const char *) sqlite3_column_text(vm, 1)?:"");
            tbmap[tabnum] = DBBrowserTable(GetDecodedQString(val1), GetDecodedQString(val2));
            tabnum++;
        }
        sqlite3_finalize(vm);
    }else{
        printf("could not get list of tables: %d, %s",err,sqlite3_errmsg(_db));
    }
    
    //now get the field list for each table in tbmap
    tableMap::iterator it;
    for ( it = tbmap.begin(); it != tbmap.end(); ++it ) {
        statement = "PRAGMA TABLE_INFO(";
        statement.append( GetEncodedQString(it->second.getname()));
        statement.append(");");
        logSQL(statement, kLogMsg_App);
        err=sqlite3_prepare(_db,statement.c_str(),statement.size(),
                            &vm, &tail);
        if (err == SQLITE_OK){
            it->second.fldmap.clear();
            int e = 0;
            while ( sqlite3_step(vm) == SQLITE_ROW ){
                if (sqlite3_column_count(vm)==6) {
                    string  val1, val2;
                    int ispk= 0;
                    val1 = string((const char *) sqlite3_column_text(vm, 1));
                    val2 = string((const char *) sqlite3_column_text(vm, 2));
                    ispk = sqlite3_column_int(vm, 5);
                    if (ispk==1){
                        val2.append(string(" PRIMARY KEY"));
                    }
                    it->second.addField(e,GetDecodedQString(val1),GetDecodedQString(val2));
                    e++;
                }
            }
            sqlite3_finalize(vm);
        } else{
            lastErrorMessage = string ("could not get types");
        }
    }
    statement = "SELECT name, sql "
    "FROM sqlite_master "
    "WHERE type='index' ";
    /*"ORDER BY name;"*/
    //finally get indices
    err=sqlite3_prepare(_db,statement.c_str(), -1/*statement.size()*/,
                        &vm, &tail);
    logSQL(statement, kLogMsg_App);
    if (err == SQLITE_OK){
        while ( sqlite3_step(vm) == SQLITE_ROW ){
            string  val1, val2;
            val1 = string((const char *) sqlite3_column_text(vm, 0)?:"");
            val2 = string((const char *) sqlite3_column_text(vm, 1)?:"");
            idxmap[idxnum] = DBBrowserIndex(GetDecodedQString(val1),GetDecodedQString(val2));
            idxnum ++;
        }
        sqlite3_finalize(vm);
    }else{
        lastErrorMessage = string ("could not get list of indices");
    }
}

vector<string> DBBrowserDB::decodeCSV(const string & csvfilename, char sep, char quote, int maxrecords, int * numfields)
{
//    QFile file(csvfilename);
    vector<string> result;
//    string current = "";
//    bool inquotemode = false;
//    bool inescapemode = false;
//    int recs = 0;
//    *numfields = 0;
//    
//    if ( file.open( QIODevice::ReadWrite ) ) {
//        QProgressDialog progress("Decoding CSV file...", "Cancel", 0, file.size());
//        progress.setWindowModality(Qt::ApplicationModal);
//        char c=0;
//        while ( c!=-1) {
//            c = file.getch();
//            if (c==quote){
//                if (inquotemode){
//                    if (inescapemode){
//                        inescapemode = false;
//                        //add the escaped char here
//                        current.append(c);
//                    } else {
//                        //are we escaping, or just finishing the quote?
//                        char d = file.getch();
//                        if (d==quote) {
//                            inescapemode = true;
//                        } else {
//                            inquotemode = false;
//                        }
//                        file.ungetch(d);
//                    }
//                } else {
//                    inquotemode = true;
//                }
//            } else if (c==sep) {
//                if (inquotemode){
//                    //add the sep here
//                    current.append(c);
//                } else {
//                    //not quoting, start new record
//                    result << current;
//                    current = "";
//                }
//            } else if (c==10) {
//                if (inquotemode){
//                    //add the newline
//                    current.append(c);
//                } else {
//                    //not quoting, start new record
//                    result << current;
//                    current = "";
//                    //for the first line, store the field count
//                    if (*numfields == 0){
//                        *numfields = result.count();
//                    }
//                    recs++;
//                    progress.setValue(file.pos());
//                    if (progress.wasCanceled()) break;
//                    if ((recs>maxrecords)&&(maxrecords!=-1))         {
//                        break;
//                    }   
//                }
//            } else if (c==13) {
//                if (inquotemode){
//                    //add the carrier return if in quote mode only
//                    current.append(c);
//                }
//            } else {//another character type
//                current.append(c);
//            }
//        }
//        file.close();
//        //do we still have a last result, not appended?
//        //proper csv files should end with a linefeed , so this is not necessary
//        //if (current.length()>0) result << current;
//    }
    return result;
}





