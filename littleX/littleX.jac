import:py from fastapi {FastAPI, HTTPException}
import:py torch;
import:py from sklearn.metrics.pairwise {cosine_similarity}
import:py from sklearn.feature_extraction.text {TfidfVectorizer}
import:py numpy as np;

node Main{
    has name:str;
}

node User{
    has user_name:str;
}

node Tweet{
    has content:str;
}

node Hastag{
    has hastag:str;
}

node Comment{
    has content:str;
}

edge Following{}

edge Tweeting{}

edge Retweeting{}

edge Like{}

glob Users:Main = Main("Users");
glob Tweets:Main = Main("Tweets");
glob Hastags:Main = Main("Hastags");

walker Start{
    can start with `root entry{
        :global: Users, Tweets, Hastags;
        root ++> [Users, Tweets, Hastags];
    }
}

walker create_user{
    has user_name:str;

    can create with `root entry{
        :g: Users;
        Users ++> (new_user:= User(self.user_name));
        report new_user;
    }
}

walker follow_request{
    has follower_jid:str;
    has followee_jid:str;

    can follow with `root entry{
        follower = &(self.follower_jid);
        followee = &(self.followee_jid);
        follower +:Following():+> followee;
        report f"{follower.user_name} is now following {followee.user_name}";
    }
}

walker tweet{
    has user_jid:str;
    has content:str;

    can tweet with `root entry{
        (user := &(self.user_jid)) +:Tweeting():+> (user_tweet := Tweet(self.content));
        report f"{user.user_name} tweeted content: {user.content}";
        report user_tweet;
    }
}

walker comment{
    has tweet_jid:str;
    has user_jid:str;
    has content:str;

    can comment with `root entry{
        (user := &(self.user_jid)) +:Commenting():+> (user_comment := Comment(self.content));
        &(self.tweet_jid) +:Reply():+> user_comment;
        report f"{user.user_name} commented: {user_comment.content} on tweet {(&(self.tweet_jid)).content}";
        report user_comment;
    }
}

walker react{
    has tweet_jid:str;
    has user_jid:str;

    can react with `root entry{
        (user:= &(self.user_jid)) +:Like():+> &(self.tweet_jid);
        report f"{user.user_name} Liked the tweet {(&(self.tweet_jid)).content}";
    }
}

walker search{
    has query:str;
    has tweets:list;

    can search with `root entry{
        vectorizer = TfidfVectorizer();
        tweet_vectors = vectorizer.fit_transform(self.tweets);
        query_vector = vectorizer.transform([self.query]);
        similarity = cosine_similarity(query_vector, tweet_vectors).flatten();
        ranked_tweets = sorted(zip(self.tweets, similarity), key=(with x:int can x), reverse=True);
        top_tweets = [{"content": tweet, "similarity": sim} for (tweet, sim) in ranked_tweets[2:]];
        report top_tweets;
    }
}
