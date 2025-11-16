import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { Badge } from '@/components/ui/badge';
import { Search, Mail, MessageCircle, Book, Video, Download, ExternalLink } from 'lucide-react';

const faqData = [
  {
    category: 'Getting Started',
    questions: [
      {
        question: 'How do I take my first measurement?',
        answer: 'Click on the "Measure" tab, then use the camera to capture a photo of the lawn bowls setup. The app will automatically detect the jack and bowls, then calculate distances.'
      },
      {
        question: 'What devices are supported?',
        answer: 'MeasureBowl works on all modern smartphones and tablets with cameras. For best results, use a device with a good camera and ensure adequate lighting.'
      },
      {
        question: 'Do I need an internet connection?',
        answer: 'An internet connection is required for initial setup and to save measurements to your account. However, you can take measurements offline and sync them later.'
      }
    ]
  },
  {
    category: 'Measurement Features',
    questions: [
      {
        question: 'How accurate are the measurements?',
        answer: 'MeasureBowl uses advanced computer vision algorithms to provide measurements accurate to within 1-2cm under good conditions. Accuracy depends on lighting, camera quality, and image clarity.'
      },
      {
        question: 'Can I measure different types of bowls?',
        answer: 'Yes! The app can detect and measure various types of lawn bowls including different colors and sizes. Make sure the bowls are clearly visible in the camera frame.'
      },
      {
        question: 'What if automatic detection fails?',
        answer: 'If automatic detection fails, you can use the manual identification feature to mark the jack and bowls yourself. The app will still calculate accurate distances.'
      }
    ]
  },
  {
    category: 'Tournaments',
    questions: [
      {
        question: 'How do I join a tournament?',
        answer: 'Browse available tournaments in the "Tournaments" section, find one that interests you, and click "Register". You may need to pay an entry fee depending on the tournament.'
      },
      {
        question: 'Can I create my own tournament?',
        answer: 'Yes! Click the "Create Tournament" button to set up your own event. You can specify dates, location, entry requirements, and other details.'
      },
      {
        question: 'How are tournament results tracked?',
        answer: 'Tournament results are automatically tracked using your measurements. The app records scores, rankings, and statistics for all participants.'
      }
    ]
  },
  {
    category: 'Account & Settings',
    questions: [
      {
        question: 'How do I change my measurement units?',
        answer: 'Go to Settings > Measurement Settings and select your preferred unit (cm, mm, or inches). This will apply to all new measurements.'
      },
      {
        question: 'Can I export my measurement history?',
        answer: 'Yes! In the History section, click the "Export CSV" button to download all your measurements in a spreadsheet format.'
      },
      {
        question: 'How do I reset my password?',
        answer: 'If you forget your password, use the "Forgot Password" link on the login screen. You will receive reset instructions via email.'
      }
    ]
  }
];

const helpResources = [
  {
    title: 'User Guide',
    description: 'Complete step-by-step guide to using MeasureBowl',
    icon: Book,
    type: 'guide',
    link: '/guide'
  },
  {
    title: 'Video Tutorials',
    description: 'Watch video tutorials to learn advanced features',
    icon: Video,
    type: 'video',
    link: '/tutorials'
  },
  {
    title: 'Download App',
    description: 'Get the mobile app for iOS and Android',
    icon: Download,
    type: 'download',
    link: '/download'
  },
  {
    title: 'Community Forum',
    description: 'Connect with other lawn bowls enthusiasts',
    icon: MessageCircle,
    type: 'external',
    link: 'https://forum.measurebowl.com'
  }
];

export default function Help() {
  const [searchTerm, setSearchTerm] = useState('');

  const filteredFaqs = faqData.map(category => ({
    ...category,
    questions: category.questions.filter(q => 
      q.question.toLowerCase().includes(searchTerm.toLowerCase()) ||
      q.answer.toLowerCase().includes(searchTerm.toLowerCase())
    )
  })).filter(category => category.questions.length > 0);

  return (
    <div data-testid="help-page" className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Help & Support</h1>
        <p className="text-muted-foreground">
          Find answers to common questions and get help using MeasureBowl
        </p>
      </div>

      {/* Search */}
      <div className="mb-8">
        <div className="relative max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
          <Input
            data-testid="search-help"
            placeholder="Search help articles..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
      </div>

      {/* Help Resources */}
      <div className="mb-8">
        <h2 className="text-2xl font-semibold mb-4">Help Resources</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {helpResources.map((resource) => {
            const Icon = resource.icon;
            return (
              <Card key={resource.title} className="hover:shadow-md transition-shadow cursor-pointer">
                <CardHeader className="pb-3">
                  <div className="flex items-center gap-3">
                    <Icon className="h-6 w-6 text-primary" />
                    <div>
                      <CardTitle className="text-lg">{resource.title}</CardTitle>
                      <Badge variant="outline" className="text-xs">
                        {resource.type}
                      </Badge>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <CardDescription>{resource.description}</CardDescription>
                  <Button variant="ghost" size="sm" className="mt-2 p-0 h-auto">
                    Learn More
                    {resource.type === 'external' && <ExternalLink className="h-3 w-3 ml-1" />}
                  </Button>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>

      {/* FAQ Section */}
      <div className="mb-8">
        <h2 className="text-2xl font-semibold mb-4">Frequently Asked Questions</h2>
        <div data-testid="help-content" className="space-y-4">
          {filteredFaqs.length === 0 ? (
            <Card>
              <CardContent className="flex items-center justify-center h-32">
                <div className="text-center">
                  <Search className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                  <p className="text-muted-foreground mb-2">No results found</p>
                  <p className="text-sm text-muted-foreground">
                    Try adjusting your search terms or browse the categories below
                  </p>
                </div>
              </CardContent>
            </Card>
          ) : (
            filteredFaqs.map((category) => (
              <Card key={category.category}>
                <CardHeader>
                  <CardTitle className="text-lg">{category.category}</CardTitle>
                </CardHeader>
                <CardContent>
                  <Accordion type="single" collapsible className="w-full">
                    {category.questions.map((faq, index) => (
                      <AccordionItem key={index} value={`${category.category}-${index}`}>
                        <AccordionTrigger className="text-left">
                          {faq.question}
                        </AccordionTrigger>
                        <AccordionContent className="text-muted-foreground">
                          {faq.answer}
                        </AccordionContent>
                      </AccordionItem>
                    ))}
                  </Accordion>
                </CardContent>
              </Card>
            ))
          )}
        </div>
      </div>

      {/* Contact Support */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Mail className="h-5 w-5" />
            Still Need Help?
          </CardTitle>
          <CardDescription>
            Can't find what you're looking for? Our support team is here to help.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col sm:flex-row gap-4">
            <Button
              data-testid="contact-support"
              className="flex items-center gap-2"
            >
              <Mail className="h-4 w-4" />
              Contact Support
            </Button>
            <Button variant="outline" className="flex items-center gap-2">
              <MessageCircle className="h-4 w-4" />
              Live Chat
            </Button>
          </div>
          <p className="text-sm text-muted-foreground mt-4">
            Response time: Usually within 24 hours | Live chat: Mon-Fri 9AM-5PM EST
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
