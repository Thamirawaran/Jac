import:py from fastapi {FastAPI, HTTPException}
import:py torch;
import:py from sklearn.metrics.pairwise {cosine_similarity}
import:py from sklearn.feature_extraction.text {TfidfVectorizer}
import:py numpy as np;
import:py from jac_cloud.core.architype {BaseAnchor}

node User{
    has user_name:str;
}

node Tweets{
}

node Tweet{
    has content:str;
}

node Comment{
    has content:str;
}

edge Following{}

edge Tweeting{}

edge Retweeting{}

walker Start{
    has user_name:str;
    can start with `root entry{
        Jac.unrestrict(here, 1);
        root ++> [User(self.user_name), Tweets()];
    }
}

walker follow_request{
    has follower_jid:str;
    has followee_jid:str;

    can follow with `root entry{
        (follower:= &(self.follower_jid)) +:Following():+> (followee:= &(self.followee_jid));
    }
}

walker tweet{
    has tweet_node_jid:str;
    has content:str;

    can tweet with `root entry{
        (tweet_node := &(self.tweet_node_jid)) +:Tweeting():+> (user_tweet := Tweet(self.content));
    }
}

walker comment{
    has tweet_jid:str;
    has user_jid:str;
    has content:str;

    can comment with `root entry{
        &(self.tweet_jid) +:Reply():+> (user_comment := Comment(self.content));
        report user_comment;
    }
}

walker search{
    has query:str;

    can search with `root entry{
        :g: db;
        tweets_db = [];
        for i in db{
            tmp = [(&i)-->];
            if tmp != []{
                tweets += tmp;
            }
        }
        tweets = [(i.content) for i in self.tweets];
        vectorizer = TfidfVectorizer();
        tweet_vectors = vectorizer.fit_transform(tweets);
        query_vector = vectorizer.transform(query);
        similarity = cosine_similarity(query_vector, tweet_vectors).flatten();
        ranked_tweets = sorted(zip(tweets, similarity), key=(with x:int can x), reverse=True);

        top_tweets = [{"content": tweet, "similarity": sim} for (tweet, sim) in ranked_tweets[2:]];
        top_tweets = [i["content"] for i in top_tweets];
        report top_tweets;
    }
}
