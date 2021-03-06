//
//  GearView.m
//  Gear
//
//  Created by 李响 on 2017/8/31.
//  Copyright © 2017年 lee. All rights reserved.
//

#import "GearView.h"

@interface GearView ()

@property (nonatomic , assign ) CGPathRef gearPath;

@end

@implementation GearView
{
    
}

+ (GearView *)gearWithToothCount:(NSInteger)toothCount
                     ToothHeight:(CGFloat)toothHeight
                   ToothMaxWidth:(CGFloat)toothMaxWidth
                   ToothMinWidth:(CGFloat)toothMinWidth{
    
    GearView *view = [[GearView alloc] initWithToothCount:toothCount ToothHeight:toothHeight ToothMaxWidth:toothMaxWidth ToothMinWidth:toothMinWidth];
    
    return view;
}

- (instancetype)initWithToothCount:(NSInteger)toothCount
                       ToothHeight:(CGFloat)toothHeight
                     ToothMaxWidth:(CGFloat)toothMaxWidth
                     ToothMinWidth:(CGFloat)toothMinWidth{
    
    self = [super init];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        
        _toothCount = toothCount > 2 ? toothCount : 2;
        
        _toothHeight = toothHeight;
        
        _toothMaxWidth = toothMaxWidth;
        
        _toothMinWidth = toothMinWidth > toothMaxWidth ? toothMaxWidth : toothMinWidth;
        
        // 计算视图大小
        
        CGFloat perimeter = _toothCount * (_toothMaxWidth + _toothMinWidth);
        
        CGFloat size = perimeter / M_PI;
        
        size += _toothHeight * 2;
        
        CGRect selfFrame = self.frame;
        
        selfFrame.size = CGSizeMake(size, size);
        
        self.frame = selfFrame;
        
        // 默认设置
        
        _fillColor = [UIColor lightGrayColor];
        
        _centerRadius = 0.0f;
        
        _centerWitdh = 1.0f;
        
        [self gearPath];
        
        [self setNeedsDisplay];
    }
    return self;
}

#pragma mark - Setter

- (void)setCenterRadius:(CGFloat)centerRadius{
    
    _centerRadius = centerRadius;
    
    [self setNeedsDisplay];
}

- (void)setCenterWitdh:(CGFloat)centerWitdh{
    
    _centerWitdh = centerWitdh;
    
    [self setNeedsDisplay];
}

- (void)setFillColor:(UIColor *)fillColor{
    
    _fillColor = fillColor;
    
    [self setNeedsDisplay];
}


#pragma mark - 原理拆分演示

- (void)test:(CGRect)rect{
    
    /**
     
     思路简析:
     
     对于齿轮来说, 我把它分为3部分: 1.外圆 , 2.内圆 , 3.轮齿边线
     这三部分在运行demo中分别对应 橙色 , 红色 , 蓝色.
     轮齿的形状我们可以看做一个梯形或者一个矩形, 不过梯形居多. 正确的轮齿应该是顶部宽度小于底部宽度, 属性中 `toothMinWidth` 和 `toothMaxWidth` 就是设置顶部和底部的宽度.
     `toothHeight` 则为轮齿的高, `toothCount`为轮齿的数量.
     
     这里齿轮的大小取决于 轮齿的高度和轮齿的最大最小宽度以及轮齿的个数.
     每个轮齿之间的间距等于轮齿最小宽度, 这样相同轮齿的齿轮才能正常咬合.
     
     1. 根据轮齿最大最小宽度 高度 数量, 计算出内圆外圆所需半径 并计算出每一个轮齿的弧度以及每一个轮齿的最大最小弧度.
     2. 内圆每个弧线的弧度等于轮齿的最小弧度 间距为轮齿的最大弧度 循环绘制 (demo中红色部分就完成了)
     3. 外圆每个弧线的弧度不等于轮齿的最小弧度, 由于半径比内圆半径大, 所以弧度相同的话会导致绘制出来的弧线长度大于内圆弧线长度. 所以这里需要做一下转换计算, 根据内圆弧线长度计算出外圆同样长度所需的弧度, 这样再根据新的弧度绘制即可. (外圆和内圆绘制的起始点不同 这里要注意 , 例如内圆起始点为0度, 那么外圆的起始点应该是: (内圆最小弧度 + (内圆最大弧度 - 外圆最小弧度) ÷ 2) 度)
     4. 外圆的绘制方式与内圆相同, 起始点和弧度计算好即可. (demo中橙色部分就完成了)
     5. 轮齿边的绘制等同于内圆第一条弧线的结束点 -> 外圆第一条弧线的起始点 .... 以此类推, 这里为了演示 我将这些点放到了数组中 然后添加线条绘制出来了. (demo中蓝色部分就完成了)
     
     这个方法是为了更方便去理解 所以分开绘制每一个部分, 优化后只要一个循环就可以搞定.
     
     */
    
    
    CGFloat width = rect.size.width;
    
    CGFloat height = rect.size.height;
    
    CGFloat exteriorRadius = width * 0.5f; //外圆半径
    
    CGFloat interiorRadius = (width - self.toothHeight * 2) * 0.5f; //内圆半径
    
    CGFloat minAndMaxRatio = (self.toothMinWidth / (self.toothMinWidth + self.toothMaxWidth)); //最小宽度与最大宽度的比例
    
    CGFloat averageAngle = (M_PI * 2) / self.toothCount; //平均每个的弧度 (平均弧度 = 最小弧度 + 最大弧度)
    
    CGFloat minAngle = averageAngle * minAndMaxRatio; //最小弧度
    
    CGFloat maxAngle = averageAngle - minAngle; //最大弧度
    
    
    NSMutableArray *exteriorPointArray = [NSMutableArray array]; //外圆坐标点数组
    
    NSMutableArray *interiorPointArray = [NSMutableArray array]; //内院坐标点数组
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextBeginPath(context);
    
    CGContextSetLineWidth(context, 1.0f);
    
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    
    // 内圆路径绘制
    
    {
        // 根据轮齿个数循环
        
        for (NSInteger i = 0 ; i < self.toothCount; i++) {
            
            CGFloat startAngle = maxAngle * i + minAngle * i; // 起始弧度
            
            CGFloat endAngle = maxAngle * i + minAngle * (i + 1); // 结束弧度
            
            CGContextAddArc(context, width * 0.5f, height * 0.5f, interiorRadius, startAngle, endAngle , 0);
            
            CGContextStrokePath(context);
            
            // 获取起始和结束的坐标
            
            CGPoint startPoint = [GearView getPointWithRadius:interiorRadius Angle:startAngle];
            
            CGPoint endPoint = [GearView getPointWithRadius:interiorRadius Angle:endAngle];
            
            // 添加到内圆坐标数组
            
            [interiorPointArray addObject:[NSValue valueWithCGPoint:CGPointMake(startPoint.x + self.toothHeight, startPoint.y + self.toothHeight)]];
            
            [interiorPointArray addObject:[NSValue valueWithCGPoint:CGPointMake(endPoint.x + self.toothHeight, endPoint.y + self.toothHeight)]];
        }
        
    }
    
    CGContextSetStrokeColorWithColor(context, [UIColor orangeColor].CGColor);
    
    // 外圆路径绘制
    
    {
        // 根据内圆半径和弧度计算外圆弧度
        // 计算内圆最小弧长度 (脑残公式: 2πr÷360*a)
        
        CGFloat minLength = M_PI * 2 * interiorRadius / 360 * minAngle;
        
        // 根据内圆最小弧长度计算出长度相同的外圆最小弧度和最大弧度
        
        CGFloat tempMinAngle = (minLength * 180) / (M_PI * exteriorRadius);
        
        CGFloat tempMaxAngle = averageAngle - tempMinAngle;
        
        // 根据轮齿个数循环
        
        for (NSInteger i = 0 ; i < self.toothCount; i++) {
            
            CGFloat placeholderAngle = minAngle + ((maxAngle - tempMinAngle) * 0.5f); //占位弧度 (内圆起始弧度为0 , 外圆起始弧度为占位弧度)
            
            CGFloat startAngle = tempMaxAngle * i + tempMinAngle * i + placeholderAngle; // 起始弧度
            
            CGFloat endAngle = tempMaxAngle * i + tempMinAngle * (i + 1) + placeholderAngle; // 结束弧度
            
            CGContextAddArc(context, width * 0.5f, height * 0.5f, exteriorRadius, startAngle, endAngle , 0);
            
            CGContextStrokePath(context);
            
            // 获取起始和结束的坐标
            
            CGPoint startPoint = [GearView getPointWithRadius:exteriorRadius Angle:startAngle];
            
            CGPoint endPoint = [GearView getPointWithRadius:exteriorRadius Angle:endAngle];
            
            [exteriorPointArray addObject:[NSValue valueWithCGPoint:CGPointMake(startPoint.x, startPoint.y)]];
            
            [exteriorPointArray addObject:[NSValue valueWithCGPoint:CGPointMake(endPoint.x, endPoint.y)]];
        }
        
    }
    
    // 轮齿边线
    
    CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
    
    for (NSInteger i = 0; i < exteriorPointArray.count; i++) {
        
        CGPoint exteriorPoint = [exteriorPointArray[i] CGPointValue];
        
        CGPoint interiorPoint = [interiorPointArray[i < interiorPointArray.count - 1 ? i + 1 : 0] CGPointValue];
        
        CGContextMoveToPoint(context, exteriorPoint.x, exteriorPoint.y);
        
        CGContextAddLineToPoint(context, interiorPoint.x, interiorPoint.y);
        
        CGContextStrokePath(context);
    }
    
    
    // 辅助线
    
    CGContextSetLineWidth(context, 1.0f / [[UIScreen mainScreen] scale]);
    
    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
    
    CGFloat list[] = {2.0f, 2.0f};
    
    CGContextSetLineDash(context, 0, list, 2);
    
    CGContextMoveToPoint(context, width * 0.5f, 0.0);
    
    CGContextAddLineToPoint(context, width * 0.5f , height);
    
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, 0.0f, height * 0.5f);
    
    CGContextAddLineToPoint(context, width, height * 0.5f);
    
    CGContextStrokePath(context);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {

//    [super drawRect:rect];
    
    // Drawing code
    
//    [self test:rect];
    
    CGFloat width = rect.size.width;
    
    CGFloat height = rect.size.height;
    
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextBeginPath(context);
    
    CGContextSetLineWidth(context, 1.0f);
    
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor); //
    
    CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
    
    // 齿轮
    
    CGContextAddPath(context, self.gearPath);
    
    CGContextClosePath(context);
    
    CGContextFillPath(context);
    
    CGContextStrokePath(context);
    
    // 圆心
    
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    
    CGContextSetLineWidth(context, self.centerWitdh);
    
    CGContextAddArc(context, width * 0.5f, height * 0.5f, self.centerRadius, 0.0f, M_PI * 2, 0);
    
    CGContextStrokePath(context);
    
    /**
    
    CGFloat exteriorRadius = width * 0.5f; //外圆半径
    
    CGFloat interiorRadius = (width - self.toothHeight * 2) * 0.5f; //内圆半径
    
    // 轮齿缺口辅助线
    {
        CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
        
        CGContextSetLineWidth(context, 1.0f);
        
        CGFloat list[] = {2.0f, 2.0f};
        
        CGContextSetLineDash(context, 0, list, 2);
        
        for (NSNumber *angle in self.toothAngleArray) {
            
            CGPoint point = [GearView getPointWithRadius:exteriorRadius Angle:[angle floatValue]];
            
            CGContextMoveToPoint(context, width * 0.5f, height * 0.5f);
            
            CGContextAddLineToPoint(context, point.x , point.y);
            
            CGContextStrokePath(context);
        }
        
        CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
        
        for (NSNumber *angle in self.gapAngleArray) {
            
            CGPoint point = [GearView getPointWithRadius:interiorRadius Angle:[angle floatValue]];
            
            CGContextMoveToPoint(context, width * 0.5f, height * 0.5f);
            
            CGContextAddLineToPoint(context, point.x + self.toothHeight , point.y + self.toothHeight);
            
            CGContextStrokePath(context);
        }
    }
    
    // 水平垂直辅助线
    {
        CGContextSetLineWidth(context, 1.0f / [[UIScreen mainScreen] scale]);
        
        CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
        
        CGFloat list[] = {2.0f, 2.0f};
        
        CGContextSetLineDash(context, 0, list, 2);
        
        CGContextMoveToPoint(context, width * 0.5f, 0.0);
        
        CGContextAddLineToPoint(context, width * 0.5f , height);
        
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context, 0.0f, height * 0.5f);
        
        CGContextAddLineToPoint(context, width, height * 0.5f);
        
        CGContextStrokePath(context);
    }
     
     */
}

#pragma mark - 根据半径和弧度获取坐标

+ (CGPoint)getPointWithRadius:(CGFloat)radius Angle:(CGFloat)angle{
    
    NSInteger index = (angle) / M_PI_2; //区分在第几象限内
    
    CGFloat needAngle = angle - index * M_PI_2; //用于计算正弦/余弦的角度
    
    CGFloat x = 0, y = 0;
    
    // 因为贝塞尔绘制的0度起始位置与正常0度位置偏移了90度, 所以为了方便计算这里同步0度起始位置
    
    switch (index) {
        
        case 0:
            NSLog(@"第二象限");
            x = radius + cosf(needAngle)*radius;
            y = radius + sinf(needAngle)*radius;
            break;
        case 1:
            NSLog(@"第三象限");
            x = radius - sinf(needAngle)*radius;
            y = radius + cosf(needAngle)*radius;
            break;
        case 2:
            NSLog(@"第四象限");
            x = radius - cosf(needAngle)*radius;
            y = radius - sinf(needAngle)*radius;
            break;
        case 3:
            NSLog(@"第一象限");
            x = radius + sinf(needAngle)*radius;
            y = radius - cosf(needAngle)*radius;
            break;
            
        default:
            break;
    }
    
    return CGPointMake(x, y);
}

#pragma mark - 根据圆心与另一个坐标位置获取相对于圆心的弧度

+ (CGFloat)getAngleWithCenter:(CGPoint)center Point:(CGPoint)point{
    
    /**
     
     根据圆心和一个点的坐标 求弧度
     
     数学公式: arctan(y2 - y1) / (x2 - x1)
     
     C函数:
     angel = Math.atan2(y,x)
     x 指定两个点横坐标的差
     y 指定两个点纵坐标的差
     */
    
    return atan2f(center.y - point.y, center.x - point.x);
}

- (void)configDrivenGearPointWithDrivenGear:(GearView *)drivenGear Angle:(CGFloat)angle{
    
    [self configDrivenGearPointWithDrivenGear:drivenGear Angle:angle Spacing:1.0f];
}

- (void)configDrivenGearPointWithDrivenGear:(GearView *)drivenGear Angle:(CGFloat)angle Spacing:(CGFloat)spacing{
    
    if (angle < 0 || angle > 360) angle = 0;
    
    CGFloat mainRadius = self.bounds.size.width * 0.5f; //主动齿轮半径
    
    CGFloat drivenRadius = drivenGear.bounds.size.width * 0.5f; //从动齿轮半径
    
    CGFloat minToothHeight = MIN(self.toothHeight, drivenGear.toothHeight); //最小的轮齿高度
    
    if (minToothHeight < spacing) spacing = 1.0f;
    
    minToothHeight = minToothHeight - spacing; //去除间隙
    
    // 获取从动齿轮当前弧度坐标
    
    CGPoint point = [GearView getPointWithRadius:mainRadius + drivenRadius - minToothHeight Angle:M_PI / 180 * angle];
    
    // 根据主动齿轮中心点坐标计算出从动齿轮中心点坐标 (包括轮齿间距)
    
    CGPoint drivenPoint = CGPointMake(point.x + self.center.x - drivenRadius - mainRadius + minToothHeight, point.y + self.center.y - drivenRadius - mainRadius + minToothHeight);
    
    drivenGear.center = drivenPoint;
    
    
    // 计算从动齿轮初始弧度 以保证轮齿咬合
    
    if (self.toothAngleArray.count == 0 || self.gapAngleArray.count == 0) return ;
    
    // 获取与主动齿轮最接近的轮齿或缺口弧度
    
    NSNumber *mainNearestAngleNumber = [self getNearestNumberWithArrayA:self.toothAngleArray ArrayB:self.gapAngleArray Number:@((M_PI / 180 * angle))];
    
    CGFloat mainNearestAngle = [mainNearestAngleNumber floatValue];
    
    BOOL isTooth = [self.toothAngleArray containsObject:mainNearestAngleNumber]; // 是否为轮齿 用于判断主动齿轮最近接的位置是轮齿还是缺口
    
    // 计算主动齿轮最接近的坐标点 (包括两个齿轮的间距)
    
    CGPoint mainNearestPoint = [GearView getPointWithRadius:isTooth ? mainRadius + spacing : mainRadius + spacing - self.toothHeight Angle:mainNearestAngle];
    
    mainNearestPoint = CGPointMake(mainNearestPoint.x + self.center.x - mainRadius - spacing, mainNearestPoint.y + self.center.y - mainRadius - spacing);
    
    if (!isTooth) mainNearestPoint.x += self.toothHeight;
    
    if (!isTooth) mainNearestPoint.y += self.toothHeight;
    
    // 根据主动齿轮最近的坐标 计算相对于从动齿轮最接近的坐标点的弧度以及偏差
    
    CGFloat drivenNearestAngle = [GearView getAngleWithCenter:drivenPoint Point:mainNearestPoint] + M_PI;
    
    drivenNearestAngle = drivenNearestAngle - [[self getNearestNumberWithArray:isTooth ? drivenGear.gapAngleArray : drivenGear.toothAngleArray Number:@(drivenNearestAngle)] floatValue]; //从动齿轮偏差 = 主动齿轮最接近点的坐标较从动齿轮的弧度 - 从动齿轮的轮齿或缺口最接近的弧度
    
    drivenGear.transform = CGAffineTransformRotate(self.transform, drivenNearestAngle);
    
    // 计算从动齿轮最接近的坐标 (调试使用)
    
    CGPoint drivenNearestPoint = [GearView getPointWithRadius:isTooth ? drivenRadius - drivenGear.toothHeight : drivenRadius Angle:drivenNearestAngle];
    
    drivenNearestPoint = CGPointMake(drivenNearestPoint.x + drivenPoint.x - drivenRadius, drivenNearestPoint.y + drivenPoint.y  - drivenRadius);
    
    if (isTooth) drivenNearestPoint.x += drivenGear.toothHeight;
    
    if (isTooth) drivenNearestPoint.y += drivenGear.toothHeight;
    
}

#pragma mark - 获取数组中最接近的值

- (NSNumber *)getNearestNumberWithArray:(NSArray <NSNumber *>*)array Number:(NSNumber *)number{
    
    NSMutableArray *tempArray = [NSMutableArray array];
    
    for (NSNumber *item in array) {
        
        // 计算相差的绝对值
        
        [tempArray addObject:@(fabs([item floatValue] - [number floatValue]))];
    }
    
    NSNumber *min = [tempArray valueForKeyPath:@"@min.self"];
    
    return array[[tempArray indexOfObject:min]];
}

- (NSNumber *)getNearestNumberWithArrayA:(NSArray <NSNumber *>*)arrayA ArrayB:(NSArray <NSNumber *>*)arrayB Number:(NSNumber *)number{
    
    NSMutableArray *tempArrayA = [NSMutableArray array];
    
    for (NSNumber *item in arrayA) {
        
        // 计算相差的绝对值
        
        [tempArrayA addObject:@(fabs([item floatValue] - [number floatValue]))];
    }
    
    NSNumber *minA = [tempArrayA valueForKeyPath:@"@min.self"];
    
    
    NSMutableArray *tempArrayB = [NSMutableArray array];
    
    for (NSNumber *item in arrayB) {
        
        // 计算相差的绝对值
        
        [tempArrayB addObject:@(fabs([item floatValue] - [number floatValue]))];
    }
    
    NSNumber *minB = [tempArrayB valueForKeyPath:@"@min.self"];
    
    
    if ([minA compare:minB] == NSOrderedAscending) {
        
        return arrayA[[tempArrayA indexOfObject:minA]];
        
    } else {
     
        return arrayB[[tempArrayB indexOfObject:minB]];
    }
    
}

#pragma mark - LazyLoading

- (CGPathRef)gearPath{
    
    if (!_gearPath) {
        
        CGMutablePathRef path = CGPathCreateMutable();
        
        CGFloat width = self.frame.size.width;
        
        CGFloat height = self.frame.size.height;
        
        CGFloat exteriorRadius = width * 0.5f; //外圆半径
        
        CGFloat interiorRadius = (width - self.toothHeight * 2) * 0.5f; //内圆半径
        
        CGFloat minAndMaxRatio = (self.toothMinWidth / (self.toothMinWidth + self.toothMaxWidth)); //最小宽度与最大宽度的比例
        
        CGFloat averageAngle = (M_PI * 2) / self.toothCount; //平均每个的弧度 (平均弧度 = 最小弧度 + 最大弧度)
        
        CGFloat minAngle = averageAngle * minAndMaxRatio; //最小弧度
        
        CGFloat maxAngle = averageAngle - minAngle; //最大弧度
        
        NSMutableArray *toothAngleArray = [NSMutableArray array];
        
        NSMutableArray *gapAngleArray = [NSMutableArray array];
        
        for (NSInteger i = 0 ; i < self.toothCount; i++) {
            
            {
                // 内圆
                
                CGFloat startAngle = maxAngle * i + minAngle * i; // 起始弧度
                
                CGFloat endAngle = maxAngle * i + minAngle * (i + 1); // 结束弧度
                
                CGPathAddArc(path, NULL, width * 0.5f, height * 0.5f, interiorRadius, startAngle, endAngle, 0);
                
                [gapAngleArray addObject:@(startAngle + (endAngle - startAngle) * 0.5f)];
            }
            
            {
                // 外圆
                
                // 根据内圆半径和弧度计算外圆弧度
                // 计算内圆最小弧长度 (脑残公式: 2πr÷360*a)
                
                CGFloat minLength = M_PI * 2 * interiorRadius / 360 * minAngle;
                
                // 根据内圆最小弧长度计算出长度相同的外圆最小弧度和最大弧度
                
                CGFloat tempMinAngle = (minLength * 180) / (M_PI * exteriorRadius);
                
                CGFloat tempMaxAngle = averageAngle - tempMinAngle;
                
                CGFloat placeholderAngle = minAngle + ((maxAngle - tempMinAngle) * 0.5f); //占位弧度 (内圆起始弧度为0 , 外圆起始弧度为占位弧度)
                
                CGFloat startAngle = tempMaxAngle * i + tempMinAngle * i + placeholderAngle; // 起始弧度
                
                CGFloat endAngle = tempMaxAngle * i + tempMinAngle * (i + 1) + placeholderAngle; // 结束弧度
                
                CGPathAddArc(path, NULL, width * 0.5f, height * 0.5f, exteriorRadius, startAngle, endAngle , 0);
                
                [toothAngleArray addObject:@(startAngle + (endAngle - startAngle) * 0.5f)];
            }
            
        }
        
        _toothAngleArray = [toothAngleArray copy];
        
        _gapAngleArray = [gapAngleArray copy];
        
        _gearPath = CGPathCreateCopy(path);
        
        CGPathRelease(path);
    }
    
    return _gearPath;
}

@end
