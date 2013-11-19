goog.require('goog.dom.xml')

class PodcastParseException
	constructor: (@message) ->

class Utils
	@nsResolver: (prefix) ->
		ns = 'itunes': 'http://apple.com/itunes/'
		ns[prefix] or null
	@selectSingleNodeNS: (node, path) ->
		doc = goog.dom.getOwnerDocument(node)
		selected = doc.evaluate(path, node, Podcast.nsResolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null)
		selected?.singleNodeValue
	@selectNodesNS: (node, path) ->
		doc = goog.dom.getOwnerDocument(node)
		nodes = doc.evaluate(path, node, Podcast.nsResolver, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null)
		results = []
		count = nodes.snapshotLength
		for i in [0 .. count - 1]
  			results.push(nodes.snapshotItem(i))
  		results

class Episode
	constructor: (@title, @author, @subtitle, @summary, @art="", @url, @size="", @type="", @guid="", @pubDate="", @duration="") ->
		@size = parseInt(@size)
		if @size <= 0
			throw new PodcastParseException("episode #{@title} has an invalid size #{@size}")

	@load: (doc) ->
		title = goog.dom.xml.selectSingleNode(doc, 'title')?.textContent
		author = Utils.selectSingleNodeNS(doc, 'author')?.textContent
		subtitle = Utils.selectSingleNodeNS(doc, 'subtitle')?.textContent
		summary = Utils.selectSingleNodeNS(doc, 'summary')?.textContent
		art = Utils.selectSingleNodeNS(doc, 'image')?.attributes['href']?.textContent
		# attributes['length'] doesn't work probably because length might be an intrinsic property.
		size = goog.dom.xml.selectSingleNode(doc, 'enclosure')?.attributes.getNamedItem('length')?.textContent
		url = goog.dom.xml.selectSingleNode(doc, 'enclosure')?.attributes['url']?.textContent
		type = goog.dom.xml.selectSingleNode(doc, 'enclosure')?.attributes['type']?.textContent
		guid = goog.dom.xml.selectSingleNode(doc, 'guid')?.textContent
		pubDate = goog.dom.xml.selectSingleNode(doc, 'pubDate')?.textContent
		duration = Utils.selectSingleNodeNS(doc, 'duration')?.textContent
		new Episode(title, author, subtitle, summary, art, url, size, type, guid, pubDate, duration)

class Podcast
	constructor: (@title, @link = "", @language = "", @copyright = "", @subtitle = "", @author = "", @email = "", @description = "", @art = "", @categories = []) ->
		@episodes = []
	addEpisode: (ep) =>
		@episodes.push(ep) 
	
	@loadFromString: (str) ->
		doc = goog.dom.xml.loadXml(str)
		channel = goog.dom.xml.selectSingleNode(doc, '/rss/channel')
		title = goog.dom.xml.selectSingleNode(channel, 'title')?.textContent
		throw new PodcastParseException('title is null') if (title is null) 
		link = goog.dom.xml.selectSingleNode(channel, 'link')?.textContent
		language = goog.dom.xml.selectSingleNode(channel, 'language')?.textContent
		copyright = goog.dom.xml.selectSingleNode(channel, 'copyright')?.textContent
		subtitle = Utils.selectSingleNodeNS(channel, 'subtitle')?.textContent
		description = goog.dom.xml.selectSingleNode(channel, 'description')?.textContent or Utils.selectSingleNodeNS(channel,'summary')?.textContent
		author = Utils.selectSingleNodeNS(channel, 'author')?.textContent
		email = Utils.selectSingleNodeNS(channel, 'email')?.textContent
		art = Utils.selectSingleNodeNS(channel, 'image')?.attributes['href']?.textContent
		categories = []
		cats = Utils.selectNodesNS(channel, 'category')
		for cat in cats
			categories.push(cat?.attributes['text']?.textContent)
		episodes = []
		eps = goog.dom.xml.selectNodes(channel, 'item')
		for ep in eps
			episodes.push(Episode.load(ep))
		podcast = new Podcast(title, link, language, copyright, subtitle, author, email, description, art, categories)
		for ep in episodes
			podcast.addEpisode(ep)

		podcast


window.podcast = Podcast
@useXml = () -> 
	Podcast.loadFromString("""<?xml version="1.0"?>
<rss version="2.0">
	<channel>
		<title>A</title>
		<link>B</link>
		<itunes:summary>This is the summary</itunes:summary>
		<description>C</description>
		<itunes:subtitle>insane</itunes:subtitle>
		<itunes:email>usman.ghani@gmail.com</itunes:email>
		<itunes:author>i am the author</itunes:author>
		<itunes:image href="http://image.com/image"/>
		<itunes:category text="cat1"></itunes:category>
		<itunes:category text="cat2"/>
		<language>en-us</language>
		<copyright>D</copyright>
		<lastBuildDate>Sat, 2 Nov 2013 03:14:37 GMT</lastBuildDate>
		<generator>tdscripts.com Podcast Generator</generator>
		<webMaster>F</webMaster>
		<ttl>1</ttl>
		<item>
			<title>G</title>
			<description>H</description>
			<pubDate>Sat, 2 Nov 2013 03:14:37 GMT</pubDate>
			<enclosure length="5000000" type="audio/mpeg" url="https://www.dropbox.com/s/l34hmdraj30jtp5/aasmaan_gar_terey_talwoonka.mp3"/>
		</item>
	</channel>
</rss>""")

@dbxFileChooser = (e) ->
	console.log("#{e.files[0].link}")
