# Generate Twitter, Web, Road graphs (.sg only)

GRAPH_DIR = graphs
RAW_GRAPH_DIR = graphs/raw

.PHONY: all twitter web road
all: twitter web road

twitter: $(GRAPH_DIR)/twitter.sg
web: $(GRAPH_DIR)/web.sg
road: $(GRAPH_DIR)/road.sg

$(RAW_GRAPH_DIR):
	mkdir -p $@

$(GRAPH_DIR):
	mkdir -p $@

# Twitter
TWITTER_URL = https://github.com/ANLAB-KAIST/traces/releases/download/twitter_rv.net/twitter_rv.net.$*.gz
$(RAW_GRAPH_DIR)/twitter_rv.net.%.gz: | $(RAW_GRAPH_DIR)
	wget -P $(RAW_GRAPH_DIR) $(TWITTER_URL)

$(RAW_GRAPH_DIR)/twitter_rv.net: $(RAW_GRAPH_DIR)/twitter_rv.net.00.gz $(RAW_GRAPH_DIR)/twitter_rv.net.01.gz $(RAW_GRAPH_DIR)/twitter_rv.net.02.gz $(RAW_GRAPH_DIR)/twitter_rv.net.03.gz
	gunzip -c $^ > $@

$(RAW_GRAPH_DIR)/twitter.el: $(RAW_GRAPH_DIR)/twitter_rv.net
	rm -f $@
	ln -s twitter_rv.net $@

$(GRAPH_DIR)/twitter.sg: $(RAW_GRAPH_DIR)/twitter.el converter | $(GRAPH_DIR)
	./converter -f $< -b $@

# Web
WEB_URL = https://sparse.tamu.edu/MM/LAW/sk-2005.tar.gz
$(RAW_GRAPH_DIR)/sk-2005.tar.gz: | $(RAW_GRAPH_DIR)
	wget -P $(RAW_GRAPH_DIR) $(WEB_URL)

$(RAW_GRAPH_DIR)/sk-2005/sk-2005.mtx: $(RAW_GRAPH_DIR)/sk-2005.tar.gz
	tar -zxvf $< -C $(RAW_GRAPH_DIR)
	touch $@

$(GRAPH_DIR)/web.sg: $(RAW_GRAPH_DIR)/sk-2005/sk-2005.mtx converter | $(GRAPH_DIR)
	./converter -f $< -b $@

# Road
ROAD_URL = http://www.dis.uniroma1.it/challenge9/data/USA-road-d/USA-road-d.USA.gr.gz
$(RAW_GRAPH_DIR)/USA-road-d.USA.gr.gz: | $(RAW_GRAPH_DIR)
	wget -P $(RAW_GRAPH_DIR) $(ROAD_URL)

$(RAW_GRAPH_DIR)/USA-road-d.USA.gr: $(RAW_GRAPH_DIR)/USA-road-d.USA.gr.gz
	gunzip < $< > $@

$(GRAPH_DIR)/road.sg: $(RAW_GRAPH_DIR)/USA-road-d.USA.gr converter | $(GRAPH_DIR)
	./converter -f $< -b $@

.PHONY: clean
clean:
	rm -rf $(RAW_GRAPH_DIR) $(GRAPH_DIR)/*.sg
