//
//  NSObject+XWFmdb.m
//  FMDB
//
//  Created by WJF on 2019/6/28.
//

#import "NSObject+XWFmdb.h"

#import "XWDBManager.h"
#import "XWFMDBTool.h"
#import <objc/message.h>
#import <UIKit/UIKit.h>

#define xw_getIgnoreKeys [XWFMDBTool executeSelector:xw_ignoreKeysSelector forClass:[self class]]

@implementation NSObject (XWFmdb)

//分类中只生成属性get,set函数的声明,没有声称其实现,所以要自己实现get,set函数.
-(NSNumber *)xw_id{
    return objc_getAssociatedObject(self, _cmd);
}
-(void)setXw_id:(NSNumber *)xw_id{
    objc_setAssociatedObject(self,@selector(xw_id),xw_id,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(NSString *)xw_createTime{
    return objc_getAssociatedObject(self, _cmd);
}
-(void)setXw_createTime:(NSString *)xw_createTime{
    objc_setAssociatedObject(self,@selector(xw_createTime),xw_createTime,OBJC_ASSOCIATION_COPY_NONATOMIC);
}
-(NSString *)xw_updateTime{
    return objc_getAssociatedObject(self, _cmd);
}
-(void)setXw_updateTime:(NSString *)xw_updateTime{
    objc_setAssociatedObject(self,@selector(xw_updateTime),xw_updateTime,OBJC_ASSOCIATION_COPY_NONATOMIC);
}
-(NSString *)xw_tableName{
    return objc_getAssociatedObject(self, _cmd);
}
-(void)setXw_tableName:(NSString *)xw_tableName{
    objc_setAssociatedObject(self,@selector(xw_tableName),xw_tableName,OBJC_ASSOCIATION_COPY_NONATOMIC);
}

/**
 @tablename 此参数为nil时，判断以当前类名为表名的表是否存在; 此参数非nil时,判断以当前参数为表名的表是否存在.
 */
+(BOOL)xw_isExistForTableName:(NSString *)tablename{
    if(tablename == nil){
        tablename = NSStringFromClass([self class]);
    }
    BOOL result = [[XWDBManager shareManager] xw_isExistWithTableName:tablename];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 同步存储.
 */
-(BOOL)xw_save{
    __block BOOL result;
    [[XWDBManager shareManager] saveObject:self ignoredKeys:xw_getIgnoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 异步存储.
 */
-(void)xw_saveAsync:(xw_complete_B)complete{
    [[XWDBManager shareManager] addToThreadPool:^{
        BOOL result = [self xw_save];
        xw_completeBlock(result);
    }];
}
/**
 同步存储或更新.
 当"唯一约束"或"主键"存在时，此接口会更新旧数据,没有则存储新数据.
 提示：“唯一约束”优先级高于"主键".
 */
-(BOOL)xw_saveOrUpdate{
    return [[self class] xw_saveOrUpdateArray:@[self]];
}
/**
 同上条件异步.
 */
-(void)xw_saveOrUpdateAsync:(xw_complete_B)complete{
    [[XWDBManager shareManager] addToThreadPool:^{
        BOOL result = [self xw_saveOrUpdate];
        xw_completeBlock(result);
    }];
}

/**
 同步 存储或更新 数组元素.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据)
 当"唯一约束"或"主键"存在时，此接口会更新旧数据,没有则存储新数据.
 提示：“唯一约束”优先级高于"主键".
 */
+(BOOL)xw_saveOrUpdateArray:(NSArray* _Nonnull)array{
    NSAssert(array && array.count,@"数组没有元素!");
    __block BOOL result;
    [[XWDBManager shareManager] xw_saveOrUpateArray:array ignoredKeys:xw_getIgnoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 同上条件异步.
 */
+(void)xw_saveOrUpdateArrayAsync:(NSArray* _Nonnull)array complete:(xw_complete_B)complete{
    [[XWDBManager shareManager] addToThreadPool:^{
        BOOL result = [self xw_saveOrUpdateArray:array];
        xw_completeBlock(result);
    }];
}

/**
 同步覆盖存储.
 覆盖掉原来的数据,只存储当前的数据.
 */
-(BOOL)xw_cover{
    __block BOOL result;
    [[XWDBManager shareManager] clearWithObject:self complete:nil];
    [[XWDBManager shareManager] saveObject:self ignoredKeys:xw_getIgnoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 同上条件异步.
 */
-(void)xw_coverAsync:(xw_complete_B)complete{
    [[XWDBManager shareManager] addToThreadPool:^{
        BOOL result = [self xw_cover];
        xw_completeBlock(result);
    }];
}

/**
 同步查询所有结果.
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 温馨提示: 当数据量巨大时,请用范围接口进行分页查询,避免查询出来的数据量过大导致程序崩溃.
 */
+(NSArray* _Nullable)xw_findAll:(NSString* _Nullable)tablename{
    if (tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    __block NSArray* results;
    [[XWDBManager shareManager] queryObjectWithTableName:tablename class:[self class] where:nil complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return results;
}
/**
 同上条件异步.
 */
+(void)xw_findAllAsync:(NSString* _Nullable)tablename complete:(xw_complete_A)complete{
    [[XWDBManager shareManager] addToThreadPool:^{
        NSArray* array = [self xw_findAll:tablename];
        xw_completeBlock(array);
    }];
}
/**
 查找第一条数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 */
+(id _Nullable)xw_firstObjet:(NSString* _Nullable)tablename{
    NSArray* array = [self xw_find:tablename limit:1 orderBy:nil desc:NO];
    return (array&&array.count)?array.firstObject:nil;
}
/**
 查找最后一条数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 */
+(id _Nullable)xw_lastObject:(NSString* _Nullable)tablename{
    NSArray* array = [self xw_find:tablename limit:1 orderBy:nil desc:YES];
    return (array&&array.count)?array.firstObject:nil;
}
/**
 查询某一行数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @row 从第1行开始算起.
 */
+(id _Nullable)xw_object:(NSString* _Nullable)tablename row:(NSInteger)row{
    NSArray* array = [self xw_find:tablename range:NSMakeRange(row,1) orderBy:nil desc:NO];
    return (array&&array.count)?array.firstObject:nil;
}
/**
 同步查询所有结果.
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @orderBy 要排序的key.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
+(NSArray* _Nullable)xw_find:(NSString* _Nullable)tablename limit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSMutableString* where = [NSMutableString string];
    orderBy?[where appendFormat:@"order by %@%@ ",XW,orderBy]:[where appendFormat:@"order by %@ ",xw_rowid];
    desc?[where appendFormat:@"desc"]:[where appendFormat:@"asc"];
    !limit?:[where appendFormat:@" limit %@",@(limit)];
    __block NSArray* results;
    [[XWDBManager shareManager] queryObjectWithTableName:tablename class:[self class] where:where complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return results;
}
/**
 同上条件异步.
 */
+(void)xw_findAsync:(NSString* _Nullable)tablename limit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(xw_complete_A)complete{
    [[XWDBManager shareManager] addToThreadPool:^{
        NSArray* array = [self xw_find:tablename limit:limit orderBy:orderBy desc:desc];
        xw_completeBlock(array);
    }];
}
/**
 同步查询所有结果.
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @orderBy 要排序的key.
 @range 查询的范围(从location开始的后面length条，localtion要大于0).
 @desc YES:降序，NO:升序.
 */
+(NSArray* _Nullable)xw_find:(NSString* _Nullable)tablename range:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSMutableString* where = [NSMutableString string];
    orderBy?[where appendFormat:@"order by %@%@ ",XW,orderBy]:[where appendFormat:@"order by %@ ",xw_rowid];
    desc?[where appendFormat:@"desc"]:[where appendFormat:@"asc"];
    NSAssert((range.location>0)&&(range.length>0),@"range参数错误,location应该大于零,length应该大于零");
    [where appendFormat:@" limit %@,%@",@(range.location-1),@(range.length)];
    __block NSArray* results;
    [[XWDBManager shareManager] queryObjectWithTableName:tablename class:[self class] where:where complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return results;
}
/**
 同上条件异步.
 */
+(void)xw_findAsync:(NSString* _Nullable)tablename range:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(xw_complete_A)complete{
    [[XWDBManager shareManager] addToThreadPool:^{
        NSArray* array = [self xw_find:tablename range:range orderBy:orderBy desc:desc];
        xw_completeBlock(array);
    }];
}
/**
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @where 条件参数，可以为nil,nil时查询所有数据.
 支持keyPath.
 where使用规则请看demo或如下事例:
 1.查询name等于爸爸和age等于45,或者name等于马哥的数据.  此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
 where = [NSString stringWithFormat:@"where %@=%@ and %@=%@ or %@=%@",xw_sqlKey(@"age"),xw_sqlValue(@(45)),xw_sqlKey(@"name"),xw_sqlValue(@"爸爸"),xw_sqlKey(@"name"),xw_sqlValue(@"马哥")];
 2.查询user.student.human.body等于小芳 和 user1.name中包含fuck这个字符串的数据.
 where = [NSString stringWithFormat:@"where %@",xw_keyPathValues(@[@"user.student.human.body",xw_equal,@"小芳",@"user1.name",xw_contains,@"fuck"])];
 3.查询user.student.human.body等于小芳,user1.name中包含fuck这个字符串 和 name等于爸爸的数据.
 where = [NSString stringWithFormat:@"where %@ and %@=%@",xw_keyPathValues(@[@"user.student.human.body",xw_equal,@"小芳",@"user1.name",xw_contains,@"fuck"]),xw_sqlKey(@"name"),xw_sqlValue(@"爸爸")];
 */
+(NSArray* _Nullable)xw_find:(NSString* _Nullable)tablename where:(NSString* _Nullable)where{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    __block NSArray* results;
    [[XWDBManager shareManager] queryWithTableName:tablename conditions:where complete:^(NSArray * _Nullable array) {
        results = [XWFMDBTool tansformDataFromSqlDataWithTableName:tablename class:[self class] array:array];
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return results;
}
/**
 同上条件异步.
 */
+(void)xw_findAsync:(NSString* _Nullable)tablename where:(NSString* _Nullable)where complete:(xw_complete_A)complete{
    [[XWDBManager shareManager] addToThreadPool:^{
        NSArray* array = [self xw_find:tablename where:where];
        xw_completeBlock(array);
    }];
}


/**
 查询某一时间段的数据.(存入时间或更新时间)
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @dateTime 参数格式：
 2017 即查询2017年的数据
 2017-07 即查询2017年7月的数据
 2017-07-19 即查询2017年7月19日的数据
 2017-07-19 16 即查询2017年7月19日16时的数据
 2017-07-19 16:17 即查询2017年7月19日16时17分的数据
 2017-07-19 16:17:53 即查询2017年7月19日16时17分53秒的数据
 2017-07-19 16:17:53.350 即查询2017年7月19日16时17分53秒350毫秒的数据
 */
+(NSArray* _Nullable)xw_find:(NSString* _Nullable)tablename type:(xw_dataTimeType)type dateTime:(NSString* _Nonnull)dateTime{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSMutableString* like = [NSMutableString string];
    [like appendFormat:@"'%@",dateTime];
    [like appendString:@"%'"];
    NSString* where;
    if(type == xw_createTime){
        where = [NSString stringWithFormat:@"where %@ like %@",xw_sqlKey(xw_createTimeKey),like];
    }else{
        where = [NSString stringWithFormat:@"where %@ like %@",xw_sqlKey(xw_updateTimeKey),like];
    }
    return [self xw_find:tablename where:where];
}
/**
 @where 条件参数,不能为nil.
 支持keyPath.
 where使用规则请看demo或如下事例:
 1.将People类数据中user.student.human.body等于"小芳"的数据更新为当前对象的数据:
 where = [NSString stringWithFormat:@"where %@",xw_keyPathValues(@[@"user.student.human.body",xw_equal,@"小芳"])];
 2.将People类中name等于"马云爸爸"的数据更新为当前对象的数据:
 where = [NSString stringWithFormat:@"where %@=%@",xw_sqlKey(@"name"),xw_sqlValue(@"马云爸爸")];
 */
-(BOOL)xw_updateWhere:(NSString* _Nonnull)where{
    NSAssert(where && where.length,@"条件语句不能为空!");
    NSDictionary* valueDict = [XWFMDBTool getDictWithObject:self ignoredKeys:xw_getIgnoreKeys filtModelInfoType:xw_ModelInfoSingleUpdate];
    __block BOOL result;
    [[XWDBManager shareManager] updateWithObject:self valueDict:valueDict conditions:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 同上条件异步.
 */
-(void)xw_updateAsyncWhere:(NSString* _Nonnull)where complete:(xw_complete_B)complete{
    [[XWDBManager shareManager] addToThreadPool:^{
        BOOL flag = [self xw_updateWhere:where];
        xw_completeBlock(flag);
    }];
}
/**
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，更新以此参数为表名的数据.
 @where 条件参数,不能为nil.
 不支持keyPath.
 where使用规则请看demo或如下事例:
 1.将People类中name等于"马云爸爸"的数据的name更新为"马化腾":
 where = [NSString stringWithFormat:@"set %@=%@ where %@=%@",xw_sqlKey(@"name"),xw_sqlValue(@"马化腾"),xw_sqlKey(@"name"),xw_sqlValue(@"马云爸爸")];
 */
+(BOOL)xw_update:(NSString* _Nullable)tablename where:(NSString* _Nonnull)where{
    NSAssert(where && where.length,@"条件不能为空!");
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    __block BOOL result;
    id object = [[self class] new];
    [object setXw_tableName:tablename];
    [[XWDBManager shareManager] updateWithObject:object valueDict:nil conditions:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}


/**
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，删除以此参数为表名的数据.
 @where 条件参数,可以为nil，nil时删除所有以tablename为表名的数据.
 支持keyPath.
 where使用规则请看demo或如下事例:
 1.删除People类中name等于"美国队长"的数据.
 where = [NSString stringWithFormat:@"where %@=%@",xw_sqlKey(@"name"),xw_sqlValue(@"美国队长")];
 2.删除People类中user.student.human.body等于"小芳"的数据.
 where = [NSString stringWithFormat:@"where %@",xw_keyPathValues(@[@"user.student.human.body",xw_equal,@"小芳"])];
 3.删除People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据.
 where = [NSString stringWithFormat:@"where %@=%@ and %@",xw_sqlKey(@"name"),xw_sqlValue(@"美国队长"),xw_keyPathValues(@[@"user.student.human.body",xw_equal,@"小芳"])];
 */
+(BOOL)xw_delete:(NSString* _Nullable)tablename where:(NSString* _Nullable)where{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    __block BOOL result;
    [[XWDBManager shareManager] deleteWithTableName:tablename conditions:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 同上条件异步.
 */
+(void)xw_deleteAsync:(NSString* _Nullable)tablename where:(NSString* _Nullable)where complete:(xw_complete_B)complete{
    [[XWDBManager shareManager] addToThreadPool:^{
        BOOL flag = [self xw_delete:tablename where:where];
        xw_completeBlock(flag);
    }];
}


/**
 删除某一行数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，删除以此参数为表名的数据.
 @row 第几行，从第1行算起.
 */
+(BOOL)xw_delete:(NSString* _Nullable)tablename row:(NSInteger)row{
    NSAssert(row,@"row要大于0");
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSString* where = [NSString stringWithFormat:@"where %@ in(select %@ from %@  limit 1 offset %@)",xw_rowid,xw_rowid,tablename,@(row-1)];
    return [self xw_delete:tablename where:where];
}
/**
 删除第一条数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，删除以此参数为表名的数据.
 */
+(BOOL)xw_deleteFirstObject:(NSString* _Nullable)tablename{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSString* where = [NSString stringWithFormat:@"where %@ in(select %@ from %@  limit 1 offset 0)",xw_rowid,xw_rowid,tablename];
    return [self xw_delete:tablename where:where];
}
/**
 删除最后一条数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，删除以此参数为表名的数据.
 */
+(BOOL)xw_deleteLastObject:(NSString* _Nullable)tablename{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSString* where = [NSString stringWithFormat:@"where %@ in(select %@ from %@ order by %@ desc limit 1 offset 0)",xw_rowid,xw_rowid,tablename,xw_rowid];
    return [self xw_delete:tablename where:where];
}

/**
 同步清除所有数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，清除以此参数为表名的数据.
 */
+(BOOL)xw_clear:(NSString* _Nullable)tablename{
    return [self xw_delete:tablename where:nil];
}
/**
 同上条件异步.
 */
+(void)xw_clearAsync:(NSString* _Nullable)tablename complete:(xw_complete_B)complete{
    [[XWDBManager shareManager] addToThreadPool:^{
        BOOL flag = [self xw_delete:tablename where:nil];
        xw_completeBlock(flag);
    }];
}


/**
 同步删除这个类的数据表.
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，清除以此参数为表名的数据.
 */
+(BOOL)xw_drop:(NSString* _Nullable)tablename{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    __block BOOL result;
    [[XWDBManager shareManager] dropWithTableName:tablename complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 同上条件异步.
 */
+(void)xw_dropAsync:(NSString* _Nullable)tablename complete:(xw_complete_B)complete{
    [[XWDBManager shareManager] addToThreadPool:^{
        BOOL flag = [self xw_drop:tablename];
        xw_completeBlock(flag);
    }];
}



/**
 查询该表中有多少条数据.
 @tablename 当此参数为nil时,查询以此类名为表名的数据条数，非nil时，查询以此参数为表名的数据条数.
 @where 条件参数,nil时查询所有以tablename为表名的数据条数.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.查询People类中name等于"美国队长"的数据条数.
 where = [NSString stringWithFormat:@"where %@=%@",xw_sqlKey(@"name"),xw_sqlValue(@"美国队长")];
 2.查询People类中user.student.human.body等于"小芳"的数据条数.
 where = [NSString stringWithFormat:@"where %@",xw_keyPathValues(@[@"user.student.human.body",xw_equal,@"小芳"])];
 3.查询People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据条数.
 where = [NSString stringWithFormat:@"where %@=%@ and %@",xw_sqlKey(@"name"),xw_sqlValue(@"美国队长"),xw_keyPathValues(@[@"user.student.human.body",xw_equal,@"小芳"])];
 */
+(NSInteger)xw_count:(NSString* _Nullable)tablename where:(NSString* _Nullable)where{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSInteger count = [[XWDBManager shareManager] countForTable:tablename conditions:where];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return count;
}


/**
 直接调用sqliteb的原生函数计算sun,min,max,avg等.
 @tablename 当此参数为nil时,操作以此类名为表名的数据表，非nil时，操作以此参数为表名的数据表.
 @key -> 要操作的属性,不支持keyPath.
 @where -> 条件参数,支持keyPath.
 */
+(double)xw_sqliteMethodWithTableName:(NSString* _Nullable)tablename type:(xw_sqliteMethodType)methodType key:(NSString* _Nonnull)key where:(NSString* _Nullable)where{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    double num = [[XWDBManager shareManager] sqliteMethodForTable:tablename type:methodType key:key where:where];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return num;
}
/**
 获取数据表当前版本号.
 @tablename 当此参数为nil时,操作以此类名为表名的数据表，非nil时，操作以此参数为表名的数据表.
 */
+(NSInteger)xw_version:(NSString* _Nullable)tablename{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    return [XWFMDBTool getIntegerWithKey:tablename];
}

/**
 刷新,当类'唯一约束','联合主键','属性类型'发生改变时,调用此接口刷新一下.
 同步刷新.
 @tablename 当此参数为nil时,操作以此类名为表名的数据表，非nil时，操作以此参数为表名的数据表.
 @version 版本号,从1开始,依次往后递增.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(xw_dealState)xw_update:(NSString* _Nullable)tablename version:(NSInteger)version{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSInteger oldVersion = [XWFMDBTool getIntegerWithKey:tablename];
    if(version > oldVersion){
        [XWFMDBTool setIntegerWithKey:tablename value:version];
        NSArray* keys = [XWFMDBTool xw_filtCreateKeys:[XWFMDBTool getClassIvarList:[self class] Object:nil onlyKey:NO] ignoredkeys:xw_getIgnoreKeys];
        __block xw_dealState state;
        [[XWDBManager shareManager] refreshTable:tablename class:[self class] keys:keys complete:^(xw_dealState result) {
            state = result;
        }];
        //关闭数据库
        [[XWDBManager shareManager] closeDB];
        return state;
    }else{
        return  xw_error;
    }
}
/**
 同上条件异步.
 */
+(void)xw_updateAsync:(NSString* _Nullable)tablename version:(NSInteger)version complete:(xw_complete_I)complete{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSInteger oldVersion = [XWFMDBTool getIntegerWithKey:tablename];
    if(version > oldVersion){
        [XWFMDBTool setIntegerWithKey:tablename value:version];
        [[XWDBManager shareManager] addToThreadPool:^{
            xw_dealState state = [self xw_update:tablename version:version];
            xw_completeBlock(state);
        }];
    }else{
        xw_completeBlock(xw_error);;
    }
}
/**
 刷新,当类'唯一约束','联合主键','属性类型'发生改变时,调用此接口刷新一下.
 同步刷新.
 @tablename 当此参数为nil时,操作以此类名为表名的数据表，非nil时，操作以此参数为表名的数据表.
 @version 版本号,从1开始,依次往后递增.
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(xw_dealState)xw_update:(NSString* _Nullable)tablename version:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSInteger oldVersion = [XWFMDBTool getIntegerWithKey:tablename];
    if(version > oldVersion){
        [XWFMDBTool setIntegerWithKey:tablename value:version];
        NSArray* keys = [XWFMDBTool xw_filtCreateKeys:[XWFMDBTool getClassIvarList:[self class] Object:nil onlyKey:NO] ignoredkeys:xw_getIgnoreKeys];
        __block xw_dealState state;
        [[XWDBManager shareManager] refreshTable:tablename class:[self class] keys:keys keyDict:keydict complete:^(xw_dealState result) {
            state = result;
        }];
        //关闭数据库
        [[XWDBManager shareManager] closeDB];
        return state;
    }else{
        return xw_error;
    }
    
}
/**
 同上条件异步.
 */
+(void)xw_updateAsync:(NSString* _Nullable)tablename version:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict complete:(xw_complete_I)complete{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSInteger oldVersion = [XWFMDBTool getIntegerWithKey:tablename];
    if(version > oldVersion){
        [XWFMDBTool setIntegerWithKey:tablename value:version];
        [[XWDBManager shareManager] addToThreadPool:^{
            xw_dealState state = [self xw_update:tablename version:version keyDict:keydict];
            xw_completeBlock(state);
        }];
    }else{
        xw_completeBlock(xw_error);;
    }
}
/**
 将某表的数据拷贝给另一个表
 同步复制.
 @tablename 源表名,当此参数为nil时,操作以此类名为表名的数据表，非nil时，操作以此参数为表名的数据表.
 @destCla 目标表名.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
+(xw_dealState)xw_copy:(NSString* _Nullable)tablename toTable:(NSString* _Nonnull)destTable keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    __block xw_dealState state;
    [[XWDBManager shareManager] copyTable:tablename to:destTable keyDict:keydict append:append complete:^(xw_dealState result) {
        state = result;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return state;
}
/**
 同上条件异步.
 */
+(void)xw_copyAsync:(NSString* _Nullable)tablename toTable:(NSString* _Nonnull)destTable keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(xw_complete_I)complete{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    [[XWDBManager shareManager] addToThreadPool:^{
        xw_dealState state = [self xw_copy:tablename toTable:destTable keyDict:keydict append:append];
        xw_completeBlock(state);
    }];
}

/**
 注册数据库表变化监听.
 @tablename 表名称，当此参数为nil时，监听以当前类名为表名的数据表，当此参数非nil时，监听以此参数为表名的数据表。
 @identify 唯一标识，,此字符串唯一,不可重复,移除监听的时候使用此字符串移除.
 @return YES: 注册监听成功; NO: 注册监听失败.
 */
+(BOOL)xw_registerChangeForTableName:(NSString* _Nullable)tablename identify:(NSString* _Nonnull)identify block:(xw_changeBlock)block{
    NSAssert(identify && identify.length,@"唯一标识不能为空!");
    if (tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    tablename = [NSString stringWithFormat:@"%@*%@",tablename,identify];
    return [[XWDBManager shareManager] registerChangeWithName:tablename block:block];
}
/**
 移除数据库表变化监听.
 @tablename 表名称，当此参数为nil时，监听以当前类名为表名的数据表，当此参数非nil时，监听以此参数为表名的数据表。
 @identify 唯一标识，,此字符串唯一,不可重复,移除监听的时候使用此字符串移除.
 @return YES: 移除监听成功; NO: 移除监听失败.
 */
+(BOOL)xw_removeChangeForTableName:(NSString* _Nullable)tablename identify:(NSString* _Nonnull)identify{
    NSAssert(identify && identify.length,@"唯一标识不能为空!");
    if (tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    tablename = [NSString stringWithFormat:@"%@*%@",tablename,identify];
    return [[XWDBManager shareManager] removeChangeWithName:tablename];
}

/**
 直接执行sql语句;
 @tablename nil时以cla类名为表名.
 @cla 要操作的类,nil时返回的结果是字典.
 提示：字段名要增加XW_前缀
 */
extern id _Nullable xw_executeSql(NSString* _Nonnull sql,NSString* _Nullable tablename,__unsafe_unretained _Nullable Class cla){
    if (tablename == nil) {
        tablename = NSStringFromClass(cla);
    }
    id result = [[XWDBManager shareManager] xw_executeSql:sql tablename:tablename class:cla];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}

#pragma mark 下面附加字典转模型API,简单好用,在只需要字典转模型功能的情况下,可以不必要再引入MJExtension那么多文件,造成代码冗余,缩减安装包.
/**
 字典转模型.
 @keyValues 字典(NSDictionary)或json格式字符.
 说明:如果模型中有数组且存放的是自定义的类(NSString等系统自带的类型就不必要了),那就实现objectClassInArray这个函数返回一个字典,key是数组名称,value是自定的类Class,用法跟MJExtension一样.
 */
+(id)xw_objectWithKeyValues:(id)keyValues{
    return [XWFMDBTool xw_objectWithClass:[self class] value:keyValues];
}
+(id)xw_objectWithDictionary:(NSDictionary *)dictionary{
    return [XWFMDBTool xw_objectWithClass:[self class] value:dictionary];
}
/**
 直接传数组批量处理;
 注:array中的元素是字典,否则出错.
 */
+(NSArray* _Nonnull)xw_objectArrayWithKeyValuesArray:(NSArray* const _Nonnull)array{
    NSMutableArray* results = [NSMutableArray array];
    for (id value in array) {
        id obj = [XWFMDBTool xw_objectWithClass:[self class] value:value];
        [results addObject:obj];
    }
    return results;
}
/**
 模型转字典.
 @ignoredKeys 忽略掉模型中的哪些key(即模型变量)不要转,nil时全部转成字典.
 */
-(NSMutableDictionary*)xw_keyValuesIgnoredKeys:(NSArray*)ignoredKeys{
    return [XWFMDBTool xw_keyValuesWithObject:self ignoredKeys:ignoredKeys];
}

#warning mark 过期方法(能正常使用,但不建议使用)
/**
 判断这个类的数据表是否已经存在.
 */
+(BOOL)xw_isExist{
    BOOL result = [[XWDBManager shareManager] xw_isExistWithTableName:NSStringFromClass([self class])];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}

/**
 同步存入对象数组.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据)
 */
+(BOOL)xw_saveArray:(NSArray* _Nonnull)array{
    return [self xw_saveArray:array IgnoreKeys:xw_getIgnoreKeys];
}
/**
 同上条件异步.
 */
+(void)xw_saveArrayAsync:(NSArray* _Nonnull)array complete:(xw_complete_B)complete{
    [self xw_saveArrayAsync:array IgnoreKeys:xw_getIgnoreKeys complete:complete];
}
/**
 同步更新对象数组.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据).
 当类中定义了"唯一约束" 或 "主键"有值时,使用此API才有意义.
 提示：“唯一约束”优先级高于"主键".
 */
+(BOOL)xw_updateArray:(NSArray* _Nonnull)array{
    NSAssert(array && array.count,@"数组没有元素!");
    __block BOOL result;
    [[XWDBManager shareManager] updateObjects:array ignoredKeys:xw_getIgnoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 同上条件异步.
 */
+(void)xw_updateArrayAsync:(NSArray* _Nonnull)array complete:(xw_complete_B)complete{
    NSAssert(array && array.count,@"数组没有元素!");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[XWDBManager shareManager] updateObjects:array ignoredKeys:xw_getIgnoreKeys complete:complete];
    });
}

/**
 同步存入对象数组.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据)
 */
+(BOOL)xw_saveArray:(NSArray*)array IgnoreKeys:(NSArray* const _Nullable)ignoreKeys{
    NSAssert(array && array.count,@"数组没有元素!");
    __block BOOL result = YES;
    [[XWDBManager shareManager] saveObjects:array ignoredKeys:ignoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}

/**
 异步存入对象数组.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据)
 */
+(void)xw_saveArrayAsync:(NSArray*)array IgnoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(xw_complete_B)complete{
    NSAssert(array && array.count,@"数组没有元素!");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self xw_saveArray:array IgnoreKeys:ignoreKeys];
        xw_completeBlock(flag);
    });
}

/**
 同步存储.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(BOOL)xw_saveIgnoredKeys:(NSArray* const _Nonnull)ignoredKeys{
    __block BOOL result;
    [[XWDBManager shareManager] saveObject:self ignoredKeys:ignoredKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 异步存储.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(void)xw_saveAsyncIgnoreKeys:(NSArray* const _Nonnull)ignoredKeys complete:(xw_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self xw_saveIgnoredKeys:ignoredKeys];
        xw_completeBlock(flag);
    });
    
}
/**
 同步覆盖存储.
 覆盖掉原来的数据,只存储当前的数据.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(BOOL)xw_coverIgnoredKeys:(NSArray* const _Nonnull)ignoredKeys{
    __block BOOL result;
    [[XWDBManager shareManager] clearWithObject:self complete:nil];
    [[XWDBManager shareManager] saveObject:self ignoredKeys:ignoredKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 异步覆盖存储.
 覆盖掉原来的数据,只存储当前的数据.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(void)xw_coverAsyncIgnoredKeys:(NSArray* const _Nonnull)ignoredKeys complete:(xw_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self xw_coverIgnoredKeys:ignoredKeys];
        xw_completeBlock(flag);
    });
}
/**
 同步更新数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据.
 可以为nil,nil时更新所有数据;
 @ignoreKeys 忽略哪些key不用更新.
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath更新接口).
 */
-(BOOL)xw_updateWhere:(NSArray* _Nullable)where ignoreKeys:(NSArray* const _Nullable)ignoreKeys{
    __block BOOL result;
    [[XWDBManager shareManager] updateWithObject:self where:where ignoreKeys:ignoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.将People类数据中user.student.human.body等于"小芳"的数据更新为当前对象的数据(忽略name不要更新).
 NSString* conditions = [NSString stringWithFormat:@"where %@",xw_keyPathValues(@[@"user.student.human.body",xw_equal,@"小芳"])];
 [p xw_updateFormatSqlConditions:conditions IgnoreKeys:@[@"name"]];
 2.将People类中name等于"马云爸爸"的数据更新为当前对象的数据.
 NSString* conditions = [NSString stringWithFormat:@"where %@=%@",xw_sqlKey(@"name"),xw_sqlValue(@"马云爸爸")])];
 [p xw_updateFormatSqlConditions:conditions IgnoreKeys:nil];
 */
-(BOOL)xw_updateFormatSqlConditions:(NSString*)conditions IgnoreKeys:(NSArray* const _Nullable)ignoreKeys{
    __block BOOL result;
    [[XWDBManager shareManager] updateObject:self ignoreKeys:ignoreKeys conditions:conditions complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 根据keypath更新数据.
 同步更新.
 @keyPathValues数组,形式@[@"user.student.name",xw_equal,@"小芳",@"user.student.conten",xw_contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 @ignoreKeys 即或略哪些key不用更新.
 */
-(BOOL)xw_updateForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues ignoreKeys:(NSArray* const _Nullable)ignoreKeys{
    __block BOOL result;
    [[XWDBManager shareManager] updateWithObject:self forKeyPathAndValues:keyPathValues ignoreKeys:ignoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
@end

#pragma mark 直接存储数组.
@implementation NSArray (XWFmdb)
/**
 存储数组.
 @name 唯一标识名称.
 **/
-(BOOL)xw_saveArrayWithName:(NSString* const _Nonnull)name{
    if([self isKindOfClass:[NSArray class]]) {
        __block BOOL result;
        [[XWDBManager shareManager] saveArray:self name:name complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        //关闭数据库
        [[XWDBManager shareManager] closeDB];
        return result;
    }else{
        return NO;
    }
}
/**
 添加数组元素.
 @name 唯一标识名称.
 @object 要添加的元素.
 */
+(BOOL)xw_addObjectWithName:(NSString* const _Nonnull)name object:(id const _Nonnull)object{
    NSAssert(object,@"元素不能为空!");
    __block BOOL result;
    [[XWDBManager shareManager] saveArray:@[object] name:name complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 获取数组元素数量.
 @name 唯一标识名称.
 */
+(NSInteger)xw_countWithName:(NSString* const _Nonnull)name{
    NSUInteger count = [[XWDBManager shareManager] countForTable:name where:nil];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return count;
    
}
/**
 查询整个数组
 */
+(NSArray*)xw_arrayWithName:(NSString* const _Nonnull)name{
    __block NSMutableArray* results;
    [[XWDBManager shareManager] queryArrayWithName:name complete:^(NSArray * _Nullable array) {
        if(array&&array.count){
            results = [NSMutableArray arrayWithArray:array];
        }
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return results;
}
/**
 获取数组某个位置的元素.
 @name 唯一标识名称.
 @index 数组元素位置.
 */
+(id _Nullable)xw_objectWithName:(NSString* const _Nonnull)name Index:(NSInteger)index{
    id resultValue = [[XWDBManager shareManager] queryArrayWithName:name index:index];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return resultValue;
}
/**
 更新数组某个位置的元素.
 @name 唯一标识名称.
 @index 数组元素位置.
 */
+(BOOL)xw_updateObjectWithName:(NSString* const _Nonnull)name Object:(id _Nonnull)object Index:(NSInteger)index{
    BOOL result = [[XWDBManager shareManager] updateObjectWithName:name object:object index:index];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 删除数组的某个元素.
 @name 唯一标识名称.
 @index 数组元素位置.
 */
+(BOOL)xw_deleteObjectWithName:(NSString* const _Nonnull)name Index:(NSInteger)index{
    BOOL result = [[XWDBManager shareManager] deleteObjectWithName:name index:index];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 清空数组元素.
 @name 唯一标识名称.
 */
+(BOOL)xw_clearArrayWithName:(NSString* const _Nonnull)name{
    __block BOOL result;
    [[XWDBManager shareManager] dropSafeTable:name complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
@end

#pragma mark 直接存储字典.
@implementation NSDictionary (XWFmdb)
/**
 存储字典.
 */
-(BOOL)xw_saveDictionary{
    if([self isKindOfClass:[NSDictionary class]]) {
        __block BOOL result;
        [[XWDBManager shareManager] saveDictionary:self complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        //关闭数据库
        [[XWDBManager shareManager] closeDB];
        return result;
    }else{
        return NO;
    }
    
}
/**
 添加字典元素.
 */
+(BOOL)xw_setValue:(id const _Nonnull)value forKey:(NSString* const _Nonnull)key{
    BOOL result = [[XWDBManager shareManager] xw_setValue:value forKey:key];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 更新字典元素.
 */
+(BOOL)xw_updateValue:(id const _Nonnull)value forKey:(NSString* const _Nonnull)key{
    BOOL result = [[XWDBManager shareManager] xw_updateValue:value forKey:key];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 遍历字典元素.
 */
+(void)xw_enumerateKeysAndObjectsUsingBlock:(void (^ _Nonnull)(NSString* _Nonnull key, id _Nonnull value,BOOL *stop))block{
    [[XWDBManager shareManager] xw_enumerateKeysAndObjectsUsingBlock:block];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
}
/**
 获取字典元素.
 */
+(id _Nullable)xw_valueForKey:(NSString* const _Nonnull)key{
    id value = [[XWDBManager shareManager] xw_valueForKey:key];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return value;
}
/**
 移除字典某个元素.
 */
+(BOOL)xw_removeValueForKey:(NSString* const _Nonnull)key{
    BOOL result = [[XWDBManager shareManager] xw_deleteValueForKey:key];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
/**
 清空字典.
 */
+(BOOL)xw_clearDictionary{
    __block BOOL result;
    NSString* const tableName = @"XW_Dictionary";
    [[XWDBManager shareManager] dropSafeTable:tableName complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[XWDBManager shareManager] closeDB];
    return result;
}
@end
