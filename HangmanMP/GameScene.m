//
//  GameScene.m
//  HangmanMP
//
//  Created by Shawn Grimes on 10/29/11.
//  Copyright (c) 2011 Shawn's Bits, LLC. All rights reserved.
//

#import "GameScene.h"
#import <GameKit/GameKit.h>

@implementation GameScene
@synthesize textFieldGuess;
@synthesize textViewGuesses;
@synthesize labelGuessedLetters;
@synthesize imageViewHanger;
@synthesize labelLettersInWord;
@synthesize scrollViewContent;
@synthesize activityIndicator;
@synthesize arrayGuesses;
@synthesize stringDifficulty;
@synthesize stringHiddenWord;
@synthesize badGuessCount;
@synthesize match;
@synthesize matchStarted;

int scoreMultiplier;
int playerScore=0;
int randomPlayerStartKey=0;

-(void) setWord:(NSString *)newWord{
    self.textViewGuesses.text=@"";
    self.stringHiddenWord=newWord;

    NSString *wordPlaceHolder=@"";
    for(int i=0; i<self.stringHiddenWord.length;i++){
        wordPlaceHolder=[wordPlaceHolder stringByAppendingString:@"_ "];
    }
    self.labelLettersInWord.text=wordPlaceHolder;
    NSLog(@"Magic word is:%@", self.stringHiddenWord);
    
    [self.arrayGuesses removeAllObjects];
}

- (void) sendData:(NSDictionary *)dictionaryToSend
{
    NSError *error;
    
    NSMutableData *dataToSend = [[NSMutableData alloc] init];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:dataToSend];
	[archiver encodeObject:dictionaryToSend forKey:@"DataDictionary"];
	[archiver finishEncoding];
        
    [match sendDataToAllPlayers:dataToSend withDataMode:GKMatchSendDataReliable error:&error];
    if (error != nil)
    {
        NSLog(@"Error sending data: %@", error.description);
    }
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSDictionary *myDictionary = [unarchiver decodeObjectForKey:@"DataDictionary"];
    [unarchiver finishDecoding];
    NSLog(@"Received Dict: %@", myDictionary);
    
    if([myDictionary valueForKey:@"randomStartKey"]!=nil){
        NSNumber *otherRandomStartKey=[myDictionary valueForKey:@"randomStartKey"];
        if([otherRandomStartKey integerValue]>randomPlayerStartKey){
            //If their random key is larger than mine, then they will send the word
            
        }else{
            //My random key is larger so I will send the word
            UIAlertView *wordPrompt=[[UIAlertView alloc] initWithTitle:@"Enter Word:" message:@"Type the word they must decode" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            wordPrompt.alertViewStyle=UIAlertViewStylePlainTextInput;
            [wordPrompt show];
        }
    }else if([myDictionary valueForKey:@"WordToGuess"]!=nil){
        [self setWord:[myDictionary valueForKey:@"WordToGuess"]];
        [self.activityIndicator stopAnimating];
    }else if([myDictionary valueForKey:@"gameWon"]!=nil){
        int guessCount=[[myDictionary valueForKey:@"gameWon"] integerValue];
        [[[UIAlertView alloc] initWithTitle:@"Your Opponent Won!" message:[NSString stringWithFormat:@"Better luck next time.  %i bad guesses", guessCount] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }else if([myDictionary valueForKey:@"gameLost"]!=nil){
        [[[UIAlertView alloc] initWithTitle:@"You Win!" message:@"They didn't guess your word" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex==1){
        NSLog(@"Alert View Text: %@", [alertView textFieldAtIndex:0].text);
        NSString *potentialWord=[alertView textFieldAtIndex:0].text;
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"wordlist" 
                                                         ofType:@"txt"];
        NSString *content = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
        
        NSArray *lines = [content componentsSeparatedByString:@"\n"]; 
        
        BOOL wordMatch=NO;
        while(wordMatch==NO){
            for (NSString *word in lines) {
                if([word isEqualToString:potentialWord]){
                    NSDictionary *myDictionary = [NSDictionary dictionaryWithObject:[alertView textFieldAtIndex:0].text forKey:@"WordToGuess"];
                    [self sendData:myDictionary];
                    wordMatch=YES;
                    break;
                }
            }
            if(wordMatch==NO){
                UIAlertView *wordPrompt=[[UIAlertView alloc] initWithTitle:@"Word Not Found" message:@"Your word was not found in the dictionary, please enter a new word for your opponent to decode:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
                wordPrompt.alertViewStyle=UIAlertViewStylePlainTextInput;
                [wordPrompt show]; 
            }
        }
    }
}

- (void)match:(GKMatch *)match player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state
{
    switch (state)
    {
        case GKPlayerStateConnected:
            // handle a new player connection.
            break;
        case GKPlayerStateDisconnected:
            [[[UIAlertView alloc] initWithTitle:@"Warning" message:[NSString stringWithFormat:@"Player %@ just left the game"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            break;
    }
    if (!self.matchStarted && match.expectedPlayerCount == 0)
    {
        self.matchStarted = YES;
        // handle initial match negotiation.
        randomPlayerStartKey=arc4random() % 1000;
        NSDictionary *dictionaryRandomStart=[NSDictionary 
                                             dictionaryWithObject:[NSNumber numberWithInt:randomPlayerStartKey] 
                                             forKey:@"randomStartKey"];
        [self sendData:dictionaryRandomStart];
        
    }
}



- (void) reportAchievementIdentifier:(NSString*)identifier percentComplete:(float) percent
{
    GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
    if (achievement)
    {
        achievement.percentComplete = percent;
        [achievement reportAchievementWithCompletionHandler:^(NSError *error)
         {
             if (error != nil)
             {
                 //There was an error so we need to save the achievement locally and resubmit later
                 NSLog(@"Saving achievement for later");
                 NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
                 NSString *achievementFilePath = [NSString stringWithFormat:@"%@/achievements.plist",[paths objectAtIndex:0]];
                 NSMutableDictionary *achievementDictionary=[NSMutableDictionary dictionaryWithContentsOfFile:achievementFilePath];
                 
                 [achievementDictionary setValue:achievement forKey:achievement.identifier];
                 [achievementDictionary writeToFile:achievementFilePath atomically:YES];
             }else{
                 NSLog(@"Achievement reported");
             }
         }];
    }
}


- (void) reportScore: (int64_t) score forCategory: (NSString*) category
{
    GKScore *scoreReporter = [[GKScore alloc] initWithCategory:category];
    scoreReporter.value = score;
    [scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
       
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
        NSString *scoreFilePath = [NSString stringWithFormat:@"%@/scores.plist",[paths objectAtIndex:0]];
        NSMutableDictionary *scoreDictionary=[NSMutableDictionary dictionaryWithContentsOfFile:scoreFilePath];
        
        if (error != nil)
        {
            //There was an error so we need to save the score locally and resubmit later
            NSLog(@"Saving score for later");
            [scoreDictionary setValue:scoreReporter forKey:[NSDate date]];
            [scoreDictionary writeToFile:scoreFilePath atomically:YES];
        }
    }]; 
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        scoreMultiplier=1;
        playerScore=0;
        
       
    }
    return self;
}

-(NSString *) getMagicWord{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"wordlist" 
                                                     ofType:@"txt"];
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];

    NSArray *lines = [content componentsSeparatedByString:@"\n"]; 
    NSLog(@"Content Length: %i", [lines count]);
    NSString *magicWord=@"";
    while(magicWord.length<4 || magicWord.length>8){
        magicWord=[lines objectAtIndex:(arc4random() % [lines count])];
    }
    
    return magicWord;
    
}

-(void) processGuess:(NSString *)guessedLetter{
    NSRange letterInWord=[self.stringHiddenWord rangeOfString:guessedLetter];
    if(letterInWord.location==NSNotFound){
        ++self.badGuessCount;
        [self.arrayGuesses addObject:guessedLetter];
        
        self.imageViewHanger.image=[UIImage imageNamed:[NSString stringWithFormat:@"Hangman%i.png", self.badGuessCount]];
        
        NSLog(@"Bad Guesses: %i", self.badGuessCount);
        if(self.badGuessCount>5){
            [[[UIAlertView alloc] initWithTitle:@"Game Over" message:@"Too many bad guesses" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            self.labelLettersInWord.text=self.stringHiddenWord;
            
            NSDictionary *dictionaryGameWon=[NSDictionary 
                                             dictionaryWithObject:[NSNumber numberWithInt:self.badGuessCount] 
                                             forKey:@"gameLost"];
            [self sendData:dictionaryGameWon];

            
        }
        [self.arrayGuesses sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        self.textViewGuesses.text=@"";
        for( int i=0;i<[self.arrayGuesses count];i++){
            self.textViewGuesses.text=[self.textViewGuesses.text stringByAppendingString:[NSString stringWithFormat:@" %@",[self.arrayGuesses objectAtIndex:i]]];
        }
        scoreMultiplier=1;
    }else{
        scoreMultiplier++;
        playerScore=playerScore+(10*scoreMultiplier);
        NSLog(@"Good Guess");
        NSRange foundInWord=letterInWord;
        foundInWord.location=letterInWord.location*2;
        NSLog(@"location in word: %i", letterInWord.location);
        self.labelLettersInWord.text=[self.labelLettersInWord.text stringByReplacingCharactersInRange:foundInWord withString:guessedLetter];
        
        while(letterInWord.location!=NSNotFound){
            NSRange searchRange=letterInWord;
            ++searchRange.location;
            searchRange.length=[self.stringHiddenWord length]-searchRange.location;
            letterInWord=[self.stringHiddenWord rangeOfString:guessedLetter options:NSCaseInsensitiveSearch range:searchRange];
            
            if(letterInWord.location!=NSNotFound){
                foundInWord.location=letterInWord.location*2;
                self.labelLettersInWord.text=[self.labelLettersInWord.text stringByReplacingCharactersInRange:foundInWord withString:guessedLetter];
                
                
            }
        }
        NSRange unfoundLetters=[self.labelLettersInWord.text rangeOfString:@"_"];
        if(unfoundLetters.location==NSNotFound){
            [self reportScore:playerScore forCategory:@"default_high_scores"];
            if(self.badGuessCount==0 && self.stringHiddenWord.length<=6){
                NSLog(@"Reporting achievement");
                [self reportAchievementIdentifier:@"no_mistakes_small_word" percentComplete:100];
            }
            
            [[[UIAlertView alloc] initWithTitle:@"WINNER!" message:[NSString stringWithFormat:@"You Win!\nScore:%i", playerScore] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            if(self.match){
                
                NSDictionary *dictionaryGameWon=[NSDictionary 
                                                     dictionaryWithObject:[NSNumber numberWithInt:self.badGuessCount] 
                                                     forKey:@"gameWon"];
                [self sendData:dictionaryGameWon];

            }
        }
        
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.textViewGuesses.text=@"";

//    self.stringHiddenWord=[self getMagicWord];
    self.labelLettersInWord.text=@"";
    self.scrollViewContent.contentSize=CGSizeMake(320, 960);
    
    self.arrayGuesses=[NSMutableArray arrayWithCapacity:26];
    
    if(self.match==nil){
        [self setWord:[self getMagicWord]];
    }

}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    [self.scrollViewContent scrollRectToVisible:CGRectMake(0, self.labelLettersInWord.frame.origin.y, 320, 420) animated:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if([textField.text length]>1){
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Too many letters typed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return NO;
        
    }else if([textField.text length]==0){
        [textField resignFirstResponder];
        return YES;
    }else if([textField.text length]==1){
        if([[NSCharacterSet letterCharacterSet] characterIsMember:[textField.text characterAtIndex:0]]){
            NSLog(@"Letter entered");
            [self processGuess:textField.text];
            textField.text=@"";
        }else{
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"You must enter a letter" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return NO;
        }
    }
    return YES;
}



- (void)viewDidUnload
{
    [self setTextFieldGuess:nil];
    [self setTextViewGuesses:nil];
    [self setLabelGuessedLetters:nil];
    [self setImageViewHanger:nil];
    [self setLabelLettersInWord:nil];
    [self setScrollViewContent:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
