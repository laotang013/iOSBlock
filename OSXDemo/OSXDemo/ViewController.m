//
//  ViewController.m
//  OSXDemo
//
//  Created by Start on 2017/11/8.
//  Copyright © 2017年 het. All rights reserved.
//
#import "ViewController.h"
#import <objc/message.h>
typedef void(^MyBlock)(int num);
typedef void(^blockDemo)(id obj);
@interface ViewController ()
{
    id  __weak obj;
}
/**myBlock*/
@property(nonatomic,copy)MyBlock blockNum;
/**创建一个对象*/
@property(nonatomic,weak)NSString *name;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *nameObj = [NSString stringWithFormat:@"弱引用"];
    self.name = nameObj;
    /*
     1.nameObj 自己生成的对象并持有对象 因为nameObj变量为强引用所以自己持有对象。
     2.name变量持有生成对象的弱引用。
     3.因为nameObj变量超出作用域其强引用失效，所以自动释放自己持有的对象。
     4.因为对象的持有这不存在了所以废弃该变量。因为带__weak修饰符变量(即弱引用)不持有对象。所以在超出其变量作用域时,对象即被释放。__weak修饰符还有另外一个优点。在持有某对象的弱应用时。弱该对象被废弃,则此弱引用将自动失效且处于nil被赋值的状态(空弱引用)。
     */
    void (^myBlock)(void) = ^()
    {
        NSLog(@"ddd");
    };
    myBlock();
   
    MyBlock blk = ^(int num)
    {
        NSLog(@"num:%d",num);
    };
    //    MyBlock *blkTwo = &blk;
    //    (*blkTwo)(10);
    //[self loadBlock];
    
    [self dispatch_Source];
    
}

-(void)loadBlock
{
    //截获自动变量值
     __block int val = 10;
     const char *fmt = "val = %d\n";
    //block语法表达式使用的是它之前声明的自动变量fmt和val
    //blockDemo loadBlk ;
    
    
    #pragma mark - 截获变量
    id array = [[NSMutableArray alloc]init];
    void(^loadBlk)(id obj) =  [^(id obj)
                                {
                                    val = 20;
                                    printf(fmt,val);
                                    //        id obj = [[NSObject alloc]init];
                                    [array addObject:obj];
                                    //如果将值赋值给Block中截获的自动变量,就会产生编译错误。
                                    //array = [NSMutableArray array];而向截获的自动变量array赋值就会产生编译错误。
                                    //虽然赋值给截获的自动变量array的操作会产生编译错误,但使用截获的值却不会有任何问题
                                    NSLog(@"array: %ld",[array count]);
                                }copy] ;
   
  
    loadBlk([[NSObject alloc]init]);
    loadBlk([[NSObject alloc]init]);
    loadBlk([[NSObject alloc]init]);
    
    //截获对象 变量作用域结束的同时,变量array被废弃。其强引用失效。因此赋值给变量array的NSMutableArray类的必定会会被释放。但是该源代码运行正常。这一结果意味着变量array的NSMutableArray类的对象在该源代码最后block的执行部分超出其变量作用域而存在。
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dispatchDemo
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"3秒后打印");
    });
    
    //想在指定时间后执行处理的可以使用dispatch_after
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 3ull* NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_main_queue(), ^{
        NSLog(@"手动获取时间变量并执行3秒后打印");
    });
    //dispatch_after函数并不是在指定时间后执行处理。而是在指定时候后追加处理到Dispatch Queue.
    //第一个参数是指定时间用的dispatch_time_t 该值用dispatch_time函数或dispatch_walltime函数作成。
    //dispatch_time函数能够获取从第一个参数dispatch_time_t 类型中指定的时间开始。到第二个参数指定
    //毫微秒单位时间后的时间。3ull* NSEC_PER_SEC数值和NSEC_PER_SEC的乘积得到的单位为毫微秒的值。
    //
}
-(void)dispatchGroupDemo
{
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //创建组
    dispatch_group_t group = dispatch_group_create();
    //首先dispatch_group_create函数生成dispatch_group_t类型的dispatch group
    //dispatch_group_asyn函数与dispatch_async函数相同 都追加block到指定的Dispatch queue中。与dispatch_async不同的是指定生成的dispatch group为第一个参数。指定的block属于指定的dispatch group中。
    
    dispatch_group_async(group, globalQueue, ^{
        NSLog(@"blk0");
    });
    dispatch_group_async(group, globalQueue, ^{
        NSLog(@"blk1");
    });
    dispatch_group_async(group, globalQueue, ^{
        sleep(5);
        NSLog(@"blk2");
    });
//    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
//        NSLog(@"全部执行完毕");
//    });
    

    long result = dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    if (result == 0) {
         NSLog(@"全部执行完毕");
    }
    //第二个参数指定等待的时间(超时)DISPATCH_TIME_FOREVER 意味着永久等待 只要属于dispatch group的处理尚未执行结束。就会一直等待。中途不能取消。
    //如果dispatch_group_wait函数返回值不为0,意味着虽然经过了指定的时间，但属于dispatch_group的某一处还在执行中如果返回值为0,那么全部处理执行结束。
    
    
    //因为向Global dispatch queue追加处理 多个线程并行执行。所以追加处理的执行顺序不定。执行时会发生变化。但是执行结果的-全部执行完毕-一定是最后输出的。
    //无论向什么样的dispatch queue中追加处理。使用dispatch Queue都可监视这些处理执行的结束。一旦检测到所有处理执行完毕就可将结束处理追加到dispatch queue中。
    //在追加到dispatch group中的处理全部结束时。该源代码中的dispatch_group_notify函数会将执行的Block追加到dispatch queue中。
    //可以使用dispatch_group_wait函数仅等待全部处理执行结束。
    
    
}

-(void)dipatch_barrier_asyncDemo
{
    //dispatch_barrier_async函数 dispatch_barrier_async函数会等待追加到并发队列上的并行执行全部处理结束之后。再将指定的任务追加到该并发队列中。然后由dispatch_barrier_async追加的处理执行王弼后。并发执行回复一般的的动作。追加到该并发队列的处理又开始执行了。
    __block int val = 0;
    dispatch_queue_t globalQueue = dispatch_queue_create(0, 0);
    dispatch_async(globalQueue, ^{
        NSLog(@"blk0 读取");
        NSLog(@"val: %d",val);
    });
    dispatch_async(globalQueue, ^{
        NSLog(@"blk1 读取");
        NSLog(@"val: %d",val);
    });
    dispatch_async(globalQueue, ^{
        NSLog(@"blk2 读取");
        NSLog(@"val: %d",val);
    });
    dispatch_async(globalQueue, ^{
        NSLog(@"blk3 读取");
        NSLog(@"val: %d",val);
    });
    dispatch_barrier_async(globalQueue, ^{
        NSLog(@"****************写入");
        val = 1;
    });
    dispatch_async(globalQueue, ^{
        NSLog(@"blk4 读取");
        NSLog(@"val: %d",val);
    });
    dispatch_async(globalQueue, ^{
        NSLog(@"blk5 读取");
        NSLog(@"val: %d",val);
    }); dispatch_async(globalQueue, ^{
        NSLog(@"blk6 读取");
        NSLog(@"val: %d",val);
    }); dispatch_async(globalQueue, ^{
        NSLog(@"blk7 读取");
        NSLog(@"val: %d",val);
    });
}
-(void)dispatchsyncDemo
{
    //1.async非同步就是将指定的Block非同步的追加到指定的队列中。dispatch_async函数不做任何的等待。
    //2.sync函数意味将指定的Block同步的追加到指定的Dispatch Queue中,在追加Block结束之前，dispatch_syn函数会一直等待。
    //3.一旦调用dispatch_sync函数。那么在指定的处理执行结束之前,该函数不会返回。
    //4. 同步函数加主队列 造成死锁 相互等待
    //同步函数往并发队列中增加任务
    dispatch_queue_t globalQueue = dispatch_get_global_queue(0, 0);
    dispatch_sync(globalQueue, ^{
        NSLog(@"one %@",[NSThread currentThread]);
    });
    dispatch_sync(globalQueue, ^{
        NSLog(@"two %@",[NSThread currentThread]);
    });
    dispatch_sync(globalQueue, ^{
        NSLog(@"three %@",[NSThread currentThread]);
    });
}
-(void)dispatch_appleyDemo
{
    //dispatch_apply是dispatch_sync和dispatchGroup的关联API.该函数按照指定的次数将指定的Block追加到指定的
    //dispatch Queue中并等待全部处理结束。
    
//    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
//    dispatch_apply(10, queue, ^(size_t index) {
//        NSLog(@"%zu",index);
//    });
    
    //dispatch_apply函数会等待全部处理执行结束
    //第一个参数为重复次数 第二个参数为追加的dispatch queue 第三个参数为追加的处理。
    //由于dispatch_apply函数与dispatch_sync函数相同 会等待处理执行结束。因此推荐在dispatch_asynczh中非同步执行dispatch_apply函数.
    dispatch_queue_t queue1 = dispatch_get_global_queue(0, 0);
    dispatch_async(queue1, ^{
        dispatch_apply(10, queue1, ^(size_t index) {
            if (index == 5) {
                dispatch_suspend(queue1);
                 //NSLog(@"%zu",index);
                //挂起后，追加到Dispatch queue中但尚未执行的处理在此之后停止执行。
            }else
            {
                 NSLog(@"%zu",index);
            }
           
        });
         NSLog(@"done");
        dispatch_async(dispatch_get_main_queue(), ^{
            //主线程刷新UI;
        });
    });
   
}
-(void)dispatch_SemaphoreDemo
{

    //Dispatch Semaphore 是持有计数信号。该计数是多线程编程中的计数类型信号。
    /*
     * 使用计数来实现该功能。计数为0时等待，计数大于1或等于1时。减去1而不等待。
     */
    //通过dispatch_semaphore_create函数生成Dispatch Semaphore 参数显示初始值.
    //dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    //等待Dispatch Semaphore的计数值达到大于或等于1.当计数值大于等于1，或者在待机中计数值大于等于1时。或者在待机中计数值大于等于1时。对该计数进行减法并从dispatch_semaphore_wait函数返回。第二个参数指定等待时间。
    //dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    //当dispatch_semaphore_wait函数返回0时。可安全得执行需要进行排他控制的处理。该处理结束时通过dispatch_semaphore_signal函数将Dispatch Semaphore的计数值加1.
    
    //生成semaphore 初始值设定为1.保证可访问线程同时只有1个。
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    NSMutableArray *array = [NSMutableArray array];
    for (int i=0; i<1000; i++) {
        dispatch_async(queue, ^{
            //等待 一直等待 知道semaphore的计数值大于等于1.
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            /*
             由于dispatch Semaphore的计数值达到大于等于1.所以将dispatch semaphore的计数值减去1.dispatch_semaphore_wait函数执行返回。执行到此semaphore为0.由于可访问类对象的线程只能有一个。因此可安全的更新。
             */
            [array addObject:@(i)];
            //排他控制处理结束。所以通过dispatch_semaphore_signal函数将dispatch_semaphore的计数值加1.
            //如果有通过dispatch_wait函数等待semaphore的计数值增加的线程就是最先等待的线程执行。
            dispatch_semaphore_signal(semaphore);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"%@",array);
            });
        });
    }
    
}

-(void)dispatch_I_O
{
    
}

-(void)dispatch_Source
{
    //Dispatch Source 他是BSD内核惯有功能kqueue的包装。
    //kqueue是在XNU内核中发生各种事件 在应用程序编程方执行处理的技术。负荷小 不占资源
    /*
     
     */
    //指定DISPATCH_SOURCE_TYPE_TIMER作成dispatch_source.
    //在定时器经过指定时间时设定main queue为追加处理的queue.
    //将定时器设定为15秒。不指定重复 允许延迟1秒。
//    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
//    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
//    //指定定时器指定时间内执行的处理。
//    dispatch_source_set_event_handler(timer, ^{
//        //取消Dispatch source
//        dispatch_source_cancel(timer);
//    });
//    dispatch_resume(timer);
    
    //使用Dispatch Source而不使用dispatch_async的唯一原因就是利用联结的优势。
    /*
     联结的大致流程： 在任一线程上调用它的一个函数dispatch_source_merge_data后。会执行dispatch source 事先定义后的句柄(可以简单的理解为一个block)
     这个过程叫做用户事件。是dispatch source支持的一种事件。
     简单的说这个事件由你调用dispatch_source_merge_data函数来向自己发出信号。
     
     */
    //创建dispatch源
    /*
     type    dispatch源可处理的事件
     handle    可以理解为句柄、索引或id，假如要监听进程，需要传入进程的ID
     mask    可以理解为描述，提供更详细的描述，让它知道具体要监听什么
     queue    自定义源需要的一个队列，用来处理所有的响应句柄（block）
     */
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_global_queue(0,0));
    dispatch_source_set_event_handler(source, ^{
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"更新UI");
        //});
    });
    dispatch_resume(source);
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        dispatch_source_merge_data(source,1);
    });

    
    
    //创建source，以DISPATCH_SOURCE_TYPE_DATA_ADD的方式进行累加，而DISPATCH_SOURCE_TYPE_DATA_OR是对结果进行二进制或运算
//    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
//
//    //事件触发后执行的句柄
//    dispatch_source_set_event_handler(source,^{
//
//        NSLog(@"监听函数：%lu",dispatch_source_get_data(source));
//
//    });
//
//    //开启source
//    dispatch_resume(source);
//
//    dispatch_queue_t myqueue =dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//
//    dispatch_async(myqueue, ^ {
//
//        for(int i = 1; i <= 4; i ++){
//
//            NSLog(@"~~~~~~~~~~~~~~%d", i);
//
//            //触发事件，向source发送事件，这里i不能为0，否则触发不了事件
//            dispatch_source_merge_data(source,i);
//
//            //当Interval的事件越长，则每次的句柄都会触发
//            //[NSThread sleepForTimeInterval:0.0001];
//        }
//    });
    

    
}

@end
